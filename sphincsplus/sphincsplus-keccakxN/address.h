/*
 * Copyright (c) 2022 Arm Limited
 * Copyright (c) 2022 Matthias Kannwischer
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

//
// This implementation is based on the public domain implementation of SPHINCS+
// available on https://github.com/sphincs/sphincsplus
//


#ifndef SPX_ADDRESS_H
#define SPX_ADDRESS_H

#include <stdint.h>
#include "params.h"

/* The hash types that are passed to set_type */
#define SPX_ADDR_TYPE_WOTS 0
#define SPX_ADDR_TYPE_WOTSPK 1
#define SPX_ADDR_TYPE_HASHTREE 2
#define SPX_ADDR_TYPE_FORSTREE 3
#define SPX_ADDR_TYPE_FORSPK 4
#define SPX_ADDR_TYPE_WOTSPRF 5
#define SPX_ADDR_TYPE_FORSPRF 6

#define set_layer_addr SPX_NAMESPACE(set_layer_addr)
void set_layer_addr(uint32_t addr[8], uint32_t layer);

#define set_tree_addr SPX_NAMESPACE(set_tree_addr)
void set_tree_addr(uint32_t addr[8], uint64_t tree);

#define set_type SPX_NAMESPACE(set_type)
void set_type(uint32_t addr[8], uint32_t type);

/* Copies the layer and tree part of one address into the other */
#define copy_subtree_addr SPX_NAMESPACE(copy_subtree_addr)
void copy_subtree_addr(uint32_t out[8], const uint32_t in[8]);

/* These functions are used for WOTS and FORS addresses. */

#define set_keypair_addr SPX_NAMESPACE(set_keypair_addr)
void set_keypair_addr(uint32_t addr[8], uint32_t keypair);

#define set_chain_addr SPX_NAMESPACE(set_chain_addr)
void set_chain_addr(uint32_t addr[8], uint32_t chain);

#define set_hash_addr SPX_NAMESPACE(set_hash_addr)
void set_hash_addr(uint32_t addr[8], uint32_t hash);

#define copy_keypair_addr SPX_NAMESPACE(copy_keypair_addr)
void copy_keypair_addr(uint32_t out[8], const uint32_t in[8]);

/* These functions are used for all hash tree addresses (including FORS). */

#define set_tree_height SPX_NAMESPACE(set_tree_height)
void set_tree_height(uint32_t addr[8], uint32_t tree_height);

#define set_tree_index SPX_NAMESPACE(set_tree_index)
void set_tree_index(uint32_t addr[8], uint32_t tree_index);

#endif
