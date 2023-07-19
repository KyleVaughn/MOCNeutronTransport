#pragma once

#include <um2/config.hpp>

#include <um2/common/algorithm.hpp> // copy
#include <um2/common/memory.hpp>    // addressof
#include <um2/common/utility.hpp>   // move

#include <um2/math/math_functions.hpp> // min

#include <cstring> // memcpy, strcmp

namespace um2
{

// -----------------------------------------------------------------------------
// STRING
// -----------------------------------------------------------------------------
// A std::string-like class, but without an allocator template parameter.

struct String {

private:
  ////////////////////////////////
  // NOTE: ASSUMES LITTLE ENDIAN
  ///////////////////////////////
  // This should be true for all x86 processors and NVIDIA GPUs.

  struct Long {
    uint64_t is_long : 1;
    uint64_t cap : 63;
    uint64_t size;
    char * data;
  };

  static uint64_t constexpr min_cap = sizeof(Long) - 1;

  struct Short {
    uint8_t is_long : 1;
    uint8_t size : 7;
    char data[min_cap];
  };

  struct Raw {
    uint64_t raw[3];
  };

  struct Rep {
    union {
      Long l;
      Short s;
      Raw r;
    };
  };

  Rep _r;

public:
  // -----------------------------------------------------------------------------
  // Constructors
  // -----------------------------------------------------------------------------

  HOSTDEV constexpr String() noexcept;

  HOSTDEV constexpr String(String const & s) noexcept;

  HOSTDEV constexpr String(String && s) noexcept;

  template <uint64_t N>
  HOSTDEV constexpr explicit String(char const (&s)[N]) noexcept;

  // -----------------------------------------------------------------------------
  // Destructor
  // -----------------------------------------------------------------------------

  HOSTDEV constexpr ~String() noexcept
  {
    if (isLong()) {
      ::operator delete(_r.l.data);
    }
  }

  // -----------------------------------------------------------------------------
  // Accessors
  // -----------------------------------------------------------------------------

  PURE HOSTDEV [[nodiscard]] constexpr auto
  isLong() const noexcept -> bool;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  size() const noexcept -> uint64_t;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  capacity() const noexcept -> uint64_t;

  // cppcheck-suppress functionConst
  PURE HOSTDEV [[nodiscard]] constexpr auto
  data() noexcept -> char *;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  data() const noexcept -> char const *;

  // -----------------------------------------------------------------------------
  // Operators
  // -----------------------------------------------------------------------------

  HOSTDEV constexpr auto
  operator=(String const & s) noexcept -> String &;

  HOSTDEV constexpr auto
  operator=(String && s) noexcept -> String &;

  HOSTDEV constexpr auto
  operator==(String const & s) const noexcept -> bool;

  HOSTDEV constexpr auto
  operator!=(String const & s) const noexcept -> bool;

  HOSTDEV constexpr auto
  operator<(String const & s) const noexcept -> bool;

  HOSTDEV constexpr auto
  operator<=(String const & s) const noexcept -> bool;

  HOSTDEV constexpr auto
  operator>(String const & s) const noexcept -> bool;

  HOSTDEV constexpr auto
  operator>=(String const & s) const noexcept -> bool;

  // -----------------------------------------------------------------------------
  // Methods
  // -----------------------------------------------------------------------------

  HOSTDEV [[nodiscard]] constexpr auto
  compare(String const & s) const noexcept -> int;

  // -----------------------------------------------------------------------------
  // HIDDEN
  // -----------------------------------------------------------------------------

  PURE HOSTDEV [[nodiscard]] HIDDEN constexpr auto
  getLongSize() const noexcept -> uint64_t;

  PURE HOSTDEV [[nodiscard]] HIDDEN constexpr auto
  getShortSize() const noexcept -> uint8_t;

  PURE HOSTDEV [[nodiscard]] HIDDEN constexpr auto
  getLongCap() const noexcept -> uint64_t;

  HOSTDEV [[nodiscard]] HIDDEN constexpr static auto
  getShortCap() noexcept -> uint64_t;

  HOSTDEV [[nodiscard]] HIDDEN constexpr auto
  // cppcheck-suppress functionConst
  getLongPointer() noexcept -> char *;

  HOSTDEV [[nodiscard]] HIDDEN constexpr auto
  getLongPointer() const noexcept -> char const *;

  HOSTDEV [[nodiscard]] HIDDEN constexpr auto
  getShortPointer() noexcept -> char *;

  HOSTDEV [[nodiscard]] HIDDEN constexpr auto
  getShortPointer() const noexcept -> char const *;

  HOSTDEV [[nodiscard]] HIDDEN constexpr auto
  getPointer() noexcept -> char *;

  HOSTDEV [[nodiscard]] HIDDEN constexpr auto
  getPointer() const noexcept -> char const *;

  CONST HOSTDEV HIDDEN static constexpr auto
  fitsInShort(uint64_t n) noexcept -> bool;

  HOSTDEV HIDDEN constexpr void
  initShort(uint64_t n) noexcept;

  HOSTDEV HIDDEN constexpr void
  initLong(uint64_t n) noexcept;

}; // struct String

} // namespace um2

#include "String.inl"