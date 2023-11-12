#pragma once

#include <um2/config.hpp>

#include <um2/common/Log.hpp>
#include <um2/math/stats.hpp>

#include <algorithm>
#include <cstddef>
#include <iomanip>
#include <iostream>
#include <vector>

namespace um2
{

//==============================================================================
// printHistogram
//==============================================================================
//
// Given an std::vector of data floats, print a histogram of the data to stdout.
// This histogram includes the min, max, mean, median, and standard deviation, as
// well as the counts in each bin and the bin ranges.
// The histogram is normalized to print with a maximum bar width of 30 characters.
// The number of bins is 15 by default.

template <std::floating_point T>
void
printHistogram(T * first, T * last, size_t nbins = 15, size_t width = 30)
{
  if (!std::is_sorted(first, last)) {
    Log::error("printHistogram: data must be sorted");
  }

  // Get the counts for each bin
  std::vector<size_t> counts(nbins); // zero initialized
  T const minval = *first;
  T const maxval = *(last - 1);
  T const bin_width = (maxval - minval) / static_cast<T>(nbins);
  {
    size_t ctr = 0;
    T bin_max = minval + bin_width;
    for (T * it = first; it != last; ++it) {
      while (*it >= bin_max) {
        ++ctr;
        bin_max += bin_width;
      }
      counts[ctr]++;
    }
  }

  // Normalize the counts
  std::vector<T> normalized_counts(nbins);
  auto const max_count = static_cast<T>(*std::max_element(counts.begin(), counts.end()));
  std::transform(
      counts.begin(), counts.end(), normalized_counts.begin(),
      [max_count](auto const & count) { return static_cast<T>(count) / max_count; });

  // Write the histogram
  std::vector<std::string> const blocks = {" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"};
  std::cout << "Histogram with " << last - first << " counts" << std::endl;
  bool any_negative = false;
  for (size_t i = 0; i < nbins; ++i) {
    // Print the range of each bin in scientific notation with 3 decimal places
    T const bin_min = minval + static_cast<T>(i) * bin_width;
    if (bin_min < 0) {
      any_negative = true;
    }
    std::cout << '[';
    if (any_negative && bin_min >= 0) {
      std::cout << ' ';
    }
    std::cout << std::setprecision(3) << std::scientific << bin_min;

    T const bin_max = minval + static_cast<T>(i) * bin_width + bin_width;
    std::cout << " - ";
    if (any_negative && bin_max >= 0) {
      std::cout << ' ';
    }
    std::cout << std::scientific << bin_max << ") ";
    // Print the bar
    auto bars = static_cast<int>(normalized_counts[i] * static_cast<T>(8 * width));
    while (bars > 8) {
      std::cout << blocks.back();
      bars -= 8;
    }
    if (bars > 0) {
      std::cout << blocks[static_cast<size_t>(bars)];
    }
    std::cout << counts[i] << '\n';
  }
  std::cout << "min: " << minval;
  std::cout << "; mean: " << mean(first, last);
  std::cout << "; median: " << median(first, last);
  std::cout << "; max: " << maxval << "\n";
  std::cout << "std dev: " << stdDev(first, last) << std::endl;
}

} // namespace um2