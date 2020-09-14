// Copyright (C) 2020 Internet Systems Consortium, Inc. ("ISC")
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef ADDRESS_RANGE_PERMUTATION_H
#define ADDRESS_RANGE_PERMUTATION_H

#include <asiolink/io_address.h>
#include <dhcpsrv/address_range.h>

#include <boost/shared_ptr.hpp>

#include <map>
#include <random>

namespace isc {
namespace dhcp {

/// @brief Random IP address permutation based on Fisher-Yates shuffle.
///
/// This class is used to shuffle IP addresses within the specified address
/// range. It is following the Fisher-Yates shuffle algorithm described in
/// https://en.wikipedia.org/wiki/Fisher–Yates_shuffle.
///
/// The original algorithm is modified to keep the minimal information about
/// the current state of the permutation and relies on the caller to collect
/// and store the next available value. In other words, the generated and
/// already returned random values are not stored by this class.
///
/// The class assumes that initially the IP addresses in the specified range
/// are in increasing order. Suppose we're dealing with the following address
/// range: 192.0.2.1-192.0.2.5. Therefore our addresses are initially ordered
/// like this: a[0]=192.0.2.1, a[1]=192.0.2.2 ..., a[4]=192.0.2.5. The
/// algorithm starts from the end of that range, i.e. i=4, so a[i]=192.0.2.5.
/// A random value from the range of [0..i-1] is picked, i.e. a value from the
/// range of [0..3]. Let's say it is 1. This value initially corresponds to the
/// address a[1]=192.0.2.2. In the original algorithm the value of a[1] is
/// swapped with a[4], yelding the following partial permutation:
/// 192.0.2.1, 192.0.2.5, 192.0.2.3, 192.0.2.4, 192.0.2.2. In our case, we simply
/// return the value of 192.0.2.2 to the caller and remember that
/// a[1]=192.0.2.5. At this point we don't store the values of a[0], a[2] and
/// a[3] because the corresponding IP addresses can be calculated from the
/// range start and their index in the permutation. The value of a[1] must be
/// stored because it has been swapped with a[4] and can't be calculated from
/// the position index.
///
/// In the next step, the current index i (cursor value) is decreased by one.
/// It now has the value of 3. Again, a random index is picked from the range
/// of [0..3]. Note that it can be the same or different index than selected
/// in the previous step. Let's assume it is 0. This corresponds to the address
/// of 192.0.2.1. This address will be returned to the caller. The value of
/// a[3]=192.0.2.4 is moved to a[0]. This yelds the following permutation:
/// 192.0.2.4, 192.0.2.5, 192.0.2.3, 192.0.2.1, 192.0.2.2. However, we only
/// remember a[0] and a[1]. The a[3] can be still computed from the range
/// start and the position. The other two have been already returned to the
/// caller so we forget them.
///
/// This algorithm guarantees that all IP addresses beloging to the given
/// address range are returned and no duplicates are returned. The addresses
/// are returned in a random order.
class AddressRangePermutation {
public:

    /// Address range.
    typedef AddressRange Range;

    /// @brief Constructor.
    ///
    /// @param range address range for which the permutation will be generated.
    AddressRangePermutation(const Range& range);

    /// @brief Checks if the address range has been exhausted.
    ///
    /// @return false if the algorithm went over all addresses in the
    /// range, true otherwise.
    bool exhausted() const {
        return (done_);
    }

    /// @brief Returns next random address from the permutation.
    ///
    /// This method will returns all addresses belonging to the specified
    /// address range in random order. For the first number of calls equal
    /// to the size of the address range it guarantees to return a non-zero
    /// IP address from that range without duplicates.
    ///
    /// @param [out] done this parameter is set to true if no more addresses
    /// can be returned for this permutation.
    /// @return next available IP address. It returns IPv4 zero or IPv6 zero
    /// address after this method walked over all available IP addresses in
    /// the range.
    asiolink::IOAddress next(bool& done);

private:

    /// Address range used in this permutation and specified in the
    /// constructor.
    Range range_;

    /// Keeps the possition of the next address to be swapped with a
    /// randomly picked address from the range of 0..cursor-1. The
    /// cursor value is decreased every time a new IP address is returned.
    uint64_t cursor_;

    /// Keeps the current permutation state. The state associates the
    /// swapped IP addresses with their positions in the permutation.
    std::map<uint64_t, asiolink::IOAddress> state_;

    /// Indicates if the addresses are exhausted.
    bool done_;

    /// Random generator.
    std::mt19937 generator_;
};

/// @brief Pointer to the @c AddressRangePermutation.
typedef boost::shared_ptr<AddressRangePermutation> AddressRangePermutationPtr;

} // end of namespace isc::dhcp
} // end of namespace isc

#endif // ADDRESS_RANGE_PERMUTATION_H