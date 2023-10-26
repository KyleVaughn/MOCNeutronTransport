#include <um2/stdlib/memory.hpp>

#include "../test_macros.hpp"

// NOLINTBEGIN justification: Just simple test code
struct A {
  void
  operator&() const
  {
  }
};

struct Nothing {
  explicit
  operator char &()
  {
    static char c = 'a';
    return c;
  }
};
// NOLINTEND

//=============================================================================
// addressof
//=============================================================================

HOSTDEV
TEST_CASE(addressof)
{
  {
    int i = 0;
    double d = 0;
    static_assert(um2::addressof(i) == &i);
    static_assert(um2::addressof(d) == &d);

    A * tp = new A;
    const A * ctp = tp;
    ASSERT(um2::addressof(*tp) == tp);
    ASSERT(um2::addressof(*ctp) == ctp);
    delete tp;
  }
  {
    union {
      Nothing n;
      int i;
    };
// Clang can do this as a static assert, gcc cannot
#ifdef __clang__
    static_assert(um2::addressof(n) == static_cast<void *>(um2::addressof(n)));
#else
    ASSERT(um2::addressof(n) == static_cast<void *>(um2::addressof(n)));
#endif
  }
}

// NOLINTBEGIN justification: Just a quick test struct.
#ifndef __CUDA_ARCH__
int count = 0;
#else
DEVICE int count = 0;
#endif
struct Counted {
  HOSTDEV
  Counted() { ++count; }
  HOSTDEV
  Counted(Counted const &) { ++count; }
  HOSTDEV ~Counted() { --count; }
  HOSTDEV friend void operator&(Counted) = delete;
};

struct VCounted {
  HOSTDEV
  VCounted() { ++count; }
  HOSTDEV
  VCounted(VCounted const &) { ++count; }
  HOSTDEV virtual ~VCounted() { --count; }
  HOSTDEV friend void operator&(VCounted) = delete;
};

struct DCounted : VCounted {
  HOSTDEV friend void operator&(DCounted) = delete;
};
// NOLINTEND

//=============================================================================
// destroy_at
//=============================================================================

HOSTDEV
TEST_CASE(destroy_at)
{
  {
    void * mem1 = malloc(sizeof(Counted));
    void * mem2 = malloc(sizeof(Counted));
    ASSERT(mem1 != nullptr);
    ASSERT(mem2 != nullptr);
    ASSERT(count == 0);
    Counted * ptr1 = nullptr;
    ptr1 = ::new (mem1) Counted();
    ASSERT(ptr1 != nullptr);
    Counted * ptr2 = nullptr;
    ptr2 = ::new (mem2) Counted();
    ASSERT(ptr2 != nullptr);
    ASSERT(count == 2);
    um2::destroy_at(ptr1);
    ASSERT(count == 1);
    um2::destroy_at(ptr2);
    ASSERT(count == 0);
    free(mem1);
    free(mem2);
    count = 0;
  }
  {
    void * mem1 = malloc(sizeof(DCounted));
    void * mem2 = malloc(sizeof(DCounted));
    ASSERT(mem1 != nullptr);
    ASSERT(mem2 != nullptr);
    ASSERT(count == 0);
    DCounted * ptr1 = nullptr;
    ptr1 = ::new (mem1) DCounted();
    ASSERT(ptr1 != nullptr);
    DCounted * ptr2 = nullptr;
    ptr2 = ::new (mem2) DCounted();
    ASSERT(ptr2 != nullptr);
    ASSERT(count == 2);
    um2::destroy_at(ptr1);
    ASSERT(count == 1);
    um2::destroy_at(ptr2);
    ASSERT(count == 0);
    free(mem1);
    free(mem2);
  }
}

//=============================================================================
// construct_at
//=============================================================================

HOSTDEV
TEST_CASE(construct_at)
{
  struct S {
    int x;
    float y;
    double z;

    HOSTDEV
    S(int x_in, float y_in, double z_in)
        : x(x_in),
          y(y_in),
          z(z_in)
    {
    }
  };

  alignas(S) unsigned char storage[sizeof(S)];

  S * ptr = um2::construct_at(reinterpret_cast<S *>(storage), 42, 2.71828F, 3.1415);
  ASSERT((*ptr).x == 42);
  ASSERT(((*ptr).y - 2.71828F) < 0.0001F);
  ASSERT(((*ptr).z - 3.1415) < 0.0001);
  um2::destroy_at(ptr);
}

//=============================================================================
// destroy
//=============================================================================

HOSTDEV
TEST_CASE(destroy)
{
  {
    void * mem = malloc(5 * sizeof(Counted));
    ASSERT(mem != nullptr);
    ASSERT(count == 0);
    Counted * ptr_begin = nullptr;
    ptr_begin = ::new (mem) Counted();
    // Initialize the rest of the memory.
    for (size_t i = 1; i < 5; ++i) {
      void * mem_init =
          static_cast<void *>(static_cast<char *>(mem) + i * sizeof(Counted));
      ::new (mem_init) Counted();
    }
    ASSERT(ptr_begin != nullptr);
    Counted * ptr_end = ptr_begin + 5;
    ASSERT(count == 5);
    um2::destroy(ptr_begin + 2, ptr_end);
    ASSERT(count == 2);
    um2::destroy(ptr_begin, ptr_begin + 2);
    ASSERT(count == 0);
    free(mem);
  }
}

MAKE_CUDA_KERNEL(addressof);
MAKE_CUDA_KERNEL(construct_at);
MAKE_CUDA_KERNEL(destroy);
MAKE_CUDA_KERNEL(destroy_at);

TEST_SUITE(addressof_suite) { TEST_HOSTDEV(addressof); }

TEST_SUITE(construct_at_suite)
{
  TEST_HOSTDEV(destroy_at);
  TEST_HOSTDEV(construct_at);
  TEST_HOSTDEV(destroy);
}

auto
main() -> int
{
  RUN_SUITE(addressof_suite);
  RUN_SUITE(construct_at_suite);
  return 0;
}
