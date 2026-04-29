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
#include <functional>
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

// The Pi firmware exposes each custom atom's raw *payload* as a separate
// file under /proc/device-tree/hat/ (or the /sys/firmware equivalent):
//   custom_0 → payload of first  custom atom (SNUM in our layout)
//   custom_1 → payload of second custom atom (RSIG in our layout)
//   vendor   → vendor string
//   product  → product string
//   uuid     → 16 raw UUID bytes
//   product_id  → 2-byte big-endian product ID
//   product_ver → 2-byte big-endian product version
//
// There is NO file header and NO atom header in these files — just payload.
// We also need the full raw EEPROM image to reconstruct the signed payload;
// that is read from /sys/bus/i2c/../eeprom or built from the DT files.

static constexpr const char *HAT_DT_BASE      = "/proc/device-tree/hat";
static constexpr const char *HAT_DT_BASE_SYS  = "/sys/firmware/devicetree/base/hat";

// ── Helper: read a device-tree hat file into a byte vector ───────────────────
static bool dt_read(const std::string &base, const std::string &name,
                    std::vector<uint8_t> &out)
{
    for (const auto &b : { base, std::string(HAT_DT_BASE_SYS),
                                  std::string(HAT_DT_BASE) }) {
        std::ifstream f(b + "/" + name, std::ios::binary);
        if (f.is_open()) {
            out.assign(std::istreambuf_iterator<char>(f),
                       std::istreambuf_iterator<char>());
            return true;
        }
    }
    return false;
}

static std::string dt_read_string(const std::string &base, const std::string &name)
{
    std::vector<uint8_t> buf;
    if (!dt_read(base, name, buf)) return "";
    // Trim trailing NUL bytes added by the firmware
    while (!buf.empty() && buf.back() == 0) buf.pop_back();
    return std::string(buf.begin(), buf.end());
}

static EepromInfo read_and_verify_eeprom()
{
    EepromInfo info;

    // Find which base path exists
    std::string base;
    for (const char *b : { HAT_DT_BASE_SYS, HAT_DT_BASE }) {
        if (std::ifstream(std::string(b) + "/product_id").is_open()) {
            base = b;
            break;
        }
    }
    if (base.empty()) {
        info.auth = AuthResult::EEPROM_NOT_FOUND;
        return info;
    }

    // ── Vendor info from individual DT files ──────────────────────────────
    // uuid: the firmware exposes this as a NUL-terminated ASCII string
    // e.g. "89d952c4-95a4-4f2a-bb81-5cf066cfa9c2\0"
    {
        std::string uuid_str = dt_read_string(base, "uuid");
        if (!uuid_str.empty()) {
            info.uuid = uuid_str;   // already formatted correctly
            info.has_vendor_info = true;
        }
    }
    {
        // product_id and product_ver: firmware exposes as ASCII hex strings
        // e.g. "0x1255\0" or "0x0101\0"
        std::string pid_str  = dt_read_string(base, "product_id");
        std::string pver_str = dt_read_string(base, "product_ver");
        if (!pid_str.empty()) {
            info.product_id = (uint16_t)std::stoul(pid_str, nullptr, 0);
            info.has_vendor_info = true;
        }
        if (!pver_str.empty()) {
            info.product_ver = (uint16_t)std::stoul(pver_str, nullptr, 0);
        }
    }
    info.vendor_str  = dt_read_string(base, "vendor");
    info.product_str = dt_read_string(base, "product");
    if (!info.vendor_str.empty() || !info.product_str.empty())
        info.has_vendor_info = true;

    // ── Custom atom payloads ──────────────────────────────────────────────
    // Scan custom_0, custom_1, ... until no more files exist
    std::vector<uint8_t> signature_bytes;
    uint32_t rsig_flags = 0;

    // We also need to reconstruct the signed payload.
    // The signing tool signs: [full EEPROM image up to RSIG atom header]
    // Since we don't have the raw image here, we reconstruct the signed
    // portion from the DT files by reading the full EEPROM over I2C.
    // However, the simplest approach that works without I2C access is to
    // read /sys/bus/i2c/devices/.../eeprom if available, otherwise fall
    // back to building the payload from DT atom payloads directly.
    //
    // For now: scan custom_N files to find SNUM and RSIG payloads.
    std::vector<std::pair<std::string,std::vector<uint8_t>>> custom_atoms;
    for (int i = 0; i < 16; i++) {
        std::vector<uint8_t> buf;
        if (!dt_read(base, "custom_" + std::to_string(i), buf)) break;
        custom_atoms.push_back({ "custom_" + std::to_string(i), buf });
    }

    for (auto &[name, payload] : custom_atoms) {
        if (payload.size() >= 4 && memcmp(payload.data(), SNUM_MAGIC, 4) == 0) {
            info.has_serial = true;
            size_t slen = payload.size() - 4;
            while (slen > 0 && payload[4 + slen - 1] == '\0') slen--;
            info.serial = std::string((const char*)payload.data() + 4, slen);
        }
        if (payload.size() >= 8 && memcmp(payload.data(), RSIG_MAGIC, 4) == 0) {
            rsig_flags = le32(payload.data() + 4);
            if (payload.size() > 8)
                signature_bytes.assign(payload.begin() + 8, payload.end());
        }
    }

    // ── Check we found a signature ────────────────────────────────────────
    if (signature_bytes.empty()) {
        info.auth = AuthResult::NO_SIGNATURE;
        return info;
    }
    if (EMBEDDED_KEYS_COUNT == 0) {
        info.auth = AuthResult::NO_KEYS;
        return info;
    }
    if (!(rsig_flags & 0x1)) {
        info.auth = AuthResult::VERIFY_ERROR;
        return info;
    }

    // ── Reconstruct the signed payload from the raw EEPROM image ─────────
    // The signing tool signs all bytes up to (not including) the RSIG atom
    // header.  The raw image is available via the kernel's i2c-dev sysfs
    // eeprom interface.  Try several common paths.
    std::vector<uint8_t> raw_image;
    {
        const char *eeprom_paths[] = {
            "/sys/bus/i2c/devices/0-0050/eeprom",
            "/sys/bus/i2c/devices/1-0050/eeprom",
            "/sys/bus/i2c/devices/i2c-0/0-0050/eeprom",
            nullptr
        };
        for (int i = 0; eeprom_paths[i]; i++) {
            std::ifstream f(eeprom_paths[i], std::ios::binary);
            if (f.is_open()) {
                raw_image.assign(std::istreambuf_iterator<char>(f),
                                 std::istreambuf_iterator<char>());
                if (!raw_image.empty())
                    break;
            }
        }
    }

    if (raw_image.size() < 12 || le32(raw_image.data()) != HATPLUS_MAGIC) {
        // sysfs eeprom path not accessible — try enabling it with:
        //   echo "24c256 0x50" | sudo tee /sys/bus/i2c/devices/i2c-0/new_device
        // or add to /etc/modules:  at24
        info.auth = AuthResult::PARSE_ERROR;
        return info;
    }

    // Find the RSIG atom in the raw image to get its exact byte offset
    size_t sig_atom_offset = SIZE_MAX;
    iter_atoms(raw_image, [&](const Atom &a) -> bool {
        if (a.type == ATOM_TYPE_CUSTOM && a.payload_len >= 8
            && memcmp(a.payload, RSIG_MAGIC, 4) == 0) {
            sig_atom_offset = a.atom_offset;
            return false; // stop
        }
        return true;
    });

    if (sig_atom_offset == SIZE_MAX) {
        info.auth = AuthResult::NO_SIGNATURE;
        return info;
    }

    std::vector<uint8_t> signed_payload(raw_image.begin(),
                                         raw_image.begin() + sig_atom_offset);

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
