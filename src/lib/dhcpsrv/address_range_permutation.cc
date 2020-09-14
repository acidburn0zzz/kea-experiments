// Copyright (C) 2020 Internet Systems Consortium, Inc. ("ISC")
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <config.h>
#include <asiolink/addr_utilities.h>
#include <dhcpsrv/address_range_permutation.h>

using namespace isc::asiolink;

namespace isc {
namespace dhcp {

AddressRangePermutation::AddressRangePermutation(const AddressRangePermutation::Range& range)
    : range_(range), cursor_(addrsInRange(range_.start_, range_.end_) - 1),
      state_(), done_(false), generator_() {
    std::random_device rd;
    generator_.seed(rd());
}

IOAddress
AddressRangePermutation::next(bool& done) {
    // If we're done iterating over the pool let's return zero address and
    // set the user supplied done flag to true.
    if (done_) {
        done = true;
        return (range_.start_.isV4() ? IOAddress::IPV4_ZERO_ADDRESS() : IOAddress::IPV6_ZERO_ADDRESS());
    }

    // If there is one address left, return this address.
    if (cursor_ == 0) {
        done = done_ = true;
        return (state_.at(0));
    }

    // We're not done.
    done = false;

    // The cursor indicates where we're in the range starting from its end. The
    // addresses between the cursor and the end of the range have been already
    // returned by this function. Therefore we focus on the remaining cursor-1
    // addresses. Let's get random address from this sub-range.
    std::uniform_int_distribution<int> dist(0, cursor_ - 1);
    auto next_loc = dist(generator_);

    IOAddress next_loc_address = IOAddress::IPV4_ZERO_ADDRESS();

    // Check if whether this address exists in our map or not. If it exists
    // it means it was swapped with some other address in previous calls to
    // this function.
    auto next_loc_existing = state_.find(next_loc);
    if (next_loc_existing != state_.end()) {
        // Address exists, so let's record it.
        next_loc_address = next_loc_existing->second;
    } else {
        // Address does not exist on this position. We infer this address from
        // its position by advancing the range start by position. For example,
        // if the range is 192.0.2.1-192.0.2.10 and the picked random position is
        // 5, the address we get is 192.0.2.6. This random address will be later
        // returned to the caller.
        next_loc_address = offsetAddress(range_.start_, next_loc);
    }

    // Let's get the address at cursor position in the same way.
    IOAddress cursor_address = IOAddress::IPV4_ZERO_ADDRESS();
    auto cursor_existing = state_.find(cursor_);
    if (cursor_existing != state_.end()) {
        cursor_address = cursor_existing->second;
    } else {
        cursor_address = offsetAddress(range_.start_, cursor_);
    }

    // Now we swap them.... in fact we don't swap because as an optimization
    // we don't record the addresses we returned by this function. We merely
    // replace the address at random position with the address from cursor
    // position. This address will be returned in the future if we get back
    // to this position as a result of randomization.
    if (next_loc_existing == state_.end()) {
        state_.insert(std::make_pair(next_loc, cursor_address));
    } else {
        state_.at(next_loc) = cursor_address;
    }
    // Move the cursor one position backwards.
    --cursor_;

    // Return the address from the random position.
    return (next_loc_address);
}

} // end of namespace isc::dhcp
} // end of namespace isc