// SPDX-License-Identifier: MIT
//
// eeprom_auth.hpp — HAT+ EEPROM parsing and RSA-PSS signature verification.
//
// Reads the HAT+ EEPROM image from /proc/device-tree/hat/custom_0
// (the raw atom dump exposed by the Pi firmware), parses vendor info,
// serial number, and verifies the RSA-PSS / SHA-256 signature atom (RSIG)
// against a set of public keys embedded at compile time.
//
// No runtime file I/O for keys — they are baked in via generated_keys.hpp.

#pragma once

#include <cstdint>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <openssl/err.h>

// ── compile-time embedded public keys ────────────────────────────────────────
// generated_keys.hpp is produced by CMake from the public_keys/ directory.
// It defines:
//   struct EmbeddedKey { const char *name; const char *pem; };
//   static const EmbeddedKey EMBEDDED_KEYS[];
//   static const size_t      EMBEDDED_KEYS_COUNT;
#include "generated_keys.hpp"

// ── HAT+ binary layout constants ─────────────────────────────────────────────

static constexpr uint32_t HATPLUS_MAGIC    = 0x69502d52u; // "R-Pi"
static constexpr uint16_t ATOM_TYPE_VENDOR = 0x0001;
static constexpr uint16_t ATOM_TYPE_CUSTOM = 0x0004;
static constexpr uint8_t  RSIG_MAGIC[4]   = { 'R','S','I','G' };
static constexpr uint8_t  SNUM_MAGIC[4]   = { 'S','N','U','M' };

// ── CRC-16/ARC ────────────────────────────────────────────────────────────────

static uint16_t crc16_arc(const uint8_t *data, size_t len)
{
    uint16_t crc  = 0x0000;
    uint16_t poly = 0xA001;
    for (size_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (int b = 0; b < 8; b++) {
            if (crc & 1) crc = (crc >> 1) ^ poly;
            else         crc >>= 1;
        }
    }
    return crc;
}

// ── Little-endian helpers ────────────────────────────────────────────────────

static inline uint16_t le16(const uint8_t *p)
{
    return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}
static inline uint32_t le32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8)
         | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

// ── Atom descriptor ───────────────────────────────────────────────────────────

struct Atom {
    uint16_t       type;
    uint16_t       count;
    uint32_t       dlen;      // includes trailing 2-byte CRC
    const uint8_t *payload;   // points into the source buffer, length = dlen - 2
    size_t         payload_len;
    size_t         atom_offset; // byte offset of atom header in source buffer
};

// ── EEPROM authentication result ─────────────────────────────────────────────

enum class AuthResult {
    OK,               // signature valid, key name set
    NO_SIGNATURE,     // no RSIG atom found
    NO_KEYS,          // no public keys were compiled in
    KEY_NOT_FOUND,    // signature did not match any key
    VERIFY_ERROR,     // OpenSSL error during verification
    PARSE_ERROR,      // malformed EEPROM image
    EEPROM_NOT_FOUND, // could not read EEPROM image
};

struct EepromInfo {
    // Vendor atom fields
    bool        has_vendor_info   = false;
    std::string uuid;             // formatted as xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    uint16_t    product_id        = 0;
    uint16_t    product_ver       = 0;
    std::string vendor_str;
    std::string product_str;

    // Serial number (SNUM custom atom)
    bool        has_serial        = false;
    std::string serial;

    // Signature verification
    AuthResult  auth              = AuthResult::PARSE_ERROR;
    std::string matched_key_name; // set when auth == OK

    // Human-readable one-line summary for logging
    std::string summary() const
    {
        std::ostringstream ss;

        if (has_vendor_info) {
            ss << "Vendor=\"" << vendor_str << "\""
               << " Product=\"" << product_str << "\""
               << " UUID=" << uuid
               << " HW=" << (product_ver >> 8) << "." << (product_ver & 0xFF);
        } else {
            ss << "[no vendor info]";
        }

        if (has_serial)
            ss << " Serial=" << serial;
        else
            ss << " [no serial]";

        ss << " Auth=";
        switch (auth) {
            case AuthResult::OK:
                ss << "GENUINE (key: " << matched_key_name << ")"; break;
            case AuthResult::NO_SIGNATURE:
                ss << "NO_SIGNATURE"; break;
            case AuthResult::NO_KEYS:
                ss << "NO_KEYS_COMPILED_IN"; break;
            case AuthResult::KEY_NOT_FOUND:
                ss << "SIGNATURE_MISMATCH"; break;
            case AuthResult::VERIFY_ERROR:
                ss << "VERIFY_ERROR"; break;
            case AuthResult::PARSE_ERROR:
                ss << "PARSE_ERROR"; break;
            case AuthResult::EEPROM_NOT_FOUND:
                ss << "EEPROM_NOT_FOUND"; break;
        }

        return ss.str();
    }
};

// ── Format UUID bytes (16 bytes, RFC 4122 big-endian) ────────────────────────

static std::string format_uuid(const uint8_t *b)
{
    char buf[37];
    snprintf(buf, sizeof(buf),
        "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        b[0],b[1],b[2],b[3], b[4],b[5], b[6],b[7],
        b[8],b[9], b[10],b[11],b[12],b[13],b[14],b[15]);
    return std::string(buf);
}

// ── Atom iterator ─────────────────────────────────────────────────────────────
// Calls cb(atom) for each valid atom in the image.
// Returns false if the header is malformed.

static bool iter_atoms(const std::vector<uint8_t> &img,
                       std::function<bool(const Atom &)> cb)
{
    if (img.size() < 12) return false;

    uint32_t magic = le32(img.data());
    if (magic != HATPLUS_MAGIC) return false;

    size_t off = 12; // skip file header
    while (off + 8 <= img.size()) {
        Atom a;
        a.type         = le16(img.data() + off);
        a.count        = le16(img.data() + off + 2);
        a.dlen         = le32(img.data() + off + 4);
        a.atom_offset  = off;

        if (a.dlen < 2) return false; // dlen must include CRC
        size_t atom_total = 8 + a.dlen;
        if (off + atom_total > img.size()) return false;

        a.payload      = img.data() + off + 8;
        a.payload_len  = a.dlen - 2; // exclude CRC

        // Verify CRC
        uint16_t crc_stored  = le16(img.data() + off + 8 + a.payload_len);
        uint16_t crc_calc    = crc16_arc(img.data() + off, 8 + a.payload_len);
        if (crc_stored != crc_calc) {
            // Log but continue — do not abort the whole parse on one bad atom
            off += atom_total;
            continue;
        }

        if (!cb(a)) return true; // callback requested stop
        off += atom_total;
    }
    return true;
}

// ── RSA-PSS verify using OpenSSL ─────────────────────────────────────────────
// Returns true if the signature over `message` verifies with the given PEM key.

static bool rsa_pss_verify(const uint8_t *message, size_t message_len,
                            const uint8_t *signature, size_t sig_len,
                            const char *public_key_pem)
{
    bool result = false;

    BIO *bio = BIO_new_mem_buf(public_key_pem, -1);
    if (!bio) return false;

    EVP_PKEY *pkey = PEM_read_bio_PUBKEY(bio, nullptr, nullptr, nullptr);
    BIO_free(bio);
    if (!pkey) return false;

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    if (!ctx) { EVP_PKEY_free(pkey); return false; }

    EVP_PKEY_CTX *pkey_ctx = nullptr;
    if (EVP_DigestVerifyInit(ctx, &pkey_ctx, EVP_sha256(), nullptr, pkey) != 1)
        goto cleanup;

    // PSS padding with maximum salt length (matches Python signing code)
    if (EVP_PKEY_CTX_set_rsa_padding(pkey_ctx, RSA_PKCS1_PSS_PADDING) != 1)
        goto cleanup;
    if (EVP_PKEY_CTX_set_rsa_pss_saltlen(pkey_ctx, RSA_PSS_SALTLEN_MAX_SIGN) != 1)
        goto cleanup;
    if (EVP_PKEY_CTX_set_rsa_mgf1_md(pkey_ctx, EVP_sha256()) != 1)
        goto cleanup;

    if (EVP_DigestVerifyUpdate(ctx, message, message_len) != 1)
        goto cleanup;

    result = (EVP_DigestVerifyFinal(ctx, signature, sig_len) == 1);

cleanup:
    EVP_MD_CTX_free(ctx);
    EVP_PKEY_free(pkey);
    return result;
}

// ── Main entry point ─────────────────────────────────────────────────────────

// The Pi firmware exposes raw EEPROM bytes (all atoms) at this path.
// The file contains the binary image starting at offset 0 (full HAT+ image).
static constexpr const char *EEPROM_DT_PATH = "/sys/firmware/devicetree/base/hat/custom_0";
// Fallback used on some older firmware versions:
static constexpr const char *EEPROM_DT_PATH_ALT = "/proc/device-tree/hat/custom_0";

static EepromInfo read_and_verify_eeprom()
{
    EepromInfo info;

    // ── Read raw EEPROM image ─────────────────────────────────────────────
    std::vector<uint8_t> img;
    {
        const char *paths[] = { EEPROM_DT_PATH, EEPROM_DT_PATH_ALT, nullptr };
        std::ifstream f;
        for (int i = 0; paths[i]; i++) {
            f.open(paths[i], std::ios::binary);
            if (f.is_open()) break;
        }
        if (!f.is_open()) {
            info.auth = AuthResult::EEPROM_NOT_FOUND;
            return info;
        }
        img.assign(std::istreambuf_iterator<char>(f),
                   std::istreambuf_iterator<char>());
    }

    if (img.size() < 12) {
        info.auth = AuthResult::PARSE_ERROR;
        return info;
    }

    // ── Parse atoms ───────────────────────────────────────────────────────
    size_t sig_atom_offset   = SIZE_MAX;
    std::vector<uint8_t> signature_bytes;
    uint32_t rsig_flags      = 0;

    bool ok = iter_atoms(img, [&](const Atom &a) -> bool {

        if (a.type == ATOM_TYPE_VENDOR && a.payload_len >= 22) {
            info.has_vendor_info = true;
            info.uuid            = format_uuid(a.payload);
            info.product_id      = le16(a.payload + 16);
            info.product_ver     = le16(a.payload + 18);
            uint8_t vslen        = a.payload[20];
            uint8_t pslen        = a.payload[21];
            if (22 + vslen <= a.payload_len)
                info.vendor_str  = std::string((const char*)a.payload + 22, vslen > 0 ? vslen - 1 : 0);
            if (22 + vslen + pslen <= a.payload_len)
                info.product_str = std::string((const char*)a.payload + 22 + vslen, pslen > 0 ? pslen - 1 : 0);
        }

        if (a.type == ATOM_TYPE_CUSTOM && a.payload_len >= 8
            && memcmp(a.payload, SNUM_MAGIC, 4) == 0) {
            info.has_serial = true;
            // Serial is ASCII, null-terminated or length-bounded
            size_t slen = a.payload_len - 4;
            // Trim any trailing null
            while (slen > 0 && a.payload[4 + slen - 1] == '\0') slen--;
            info.serial = std::string((const char*)a.payload + 4, slen);
        }

        if (a.type == ATOM_TYPE_CUSTOM && a.payload_len >= 8
            && memcmp(a.payload, RSIG_MAGIC, 4) == 0) {
            sig_atom_offset = a.atom_offset;
            rsig_flags      = le32(a.payload + 4);
            // Signature bytes start at payload[8]
            if (a.payload_len > 8) {
                signature_bytes.assign(a.payload + 8, a.payload + a.payload_len);
            }
        }

        return true; // continue
    });

    if (!ok) {
        info.auth = AuthResult::PARSE_ERROR;
        return info;
    }

    // ── Check we found a signature ────────────────────────────────────────
    if (sig_atom_offset == SIZE_MAX || signature_bytes.empty()) {
        info.auth = AuthResult::NO_SIGNATURE;
        return info;
    }

    if (EMBEDDED_KEYS_COUNT == 0) {
        info.auth = AuthResult::NO_KEYS;
        return info;
    }

    // PSS flag must be set (bit 0)
    if (!(rsig_flags & 0x1)) {
        info.auth = AuthResult::VERIFY_ERROR;
        return info;
    }

    // ── Reconstruct the signed payload ───────────────────────────────────
    // The signed payload is every byte of the image up to (but not including)
    // the RSIG atom header, with numatoms and eeplen already reflecting
    // the final state (they are correct in the stored image).
    std::vector<uint8_t> signed_payload(img.begin(),
                                         img.begin() + sig_atom_offset);

    // ── Try each compiled-in public key ──────────────────────────────────
    for (size_t i = 0; i < EMBEDDED_KEYS_COUNT; i++) {
        if (rsa_pss_verify(signed_payload.data(), signed_payload.size(),
                           signature_bytes.data(), signature_bytes.size(),
                           EMBEDDED_KEYS[i].pem))
        {
            info.auth             = AuthResult::OK;
            info.matched_key_name = EMBEDDED_KEYS[i].name;
            return info;
        }
    }

    info.auth = AuthResult::KEY_NOT_FOUND;
    return info;
}