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

#if !defined( SHAKE_OFFSETS_H_ )
#define SHAKE_OFFSETS_H_

/*
 * Offsets of various fields in the address structure when we use SHAKE as
 * the Sphincs+ hash function
 */

#define SPX_OFFSET_LAYER     3   /* The byte used to specify the Merkle tree layer */
#define SPX_OFFSET_TREE      8   /* The start of the 8 byte field used to specify the tree */
#define SPX_OFFSET_TYPE      19  /* The byte used to specify the hash type (reason) */
#define SPX_OFFSET_KP_ADDR2  22  /* The high byte used to specify the key pair (which one-time signature) */
#define SPX_OFFSET_KP_ADDR1  23  /* The low byte used to specify the key pair */
#define SPX_OFFSET_CHAIN_ADDR 27  /* The byte used to specify the chain address (which Winternitz chain) */
#define SPX_OFFSET_HASH_ADDR 31  /* The byte used to specify the hash address (where in the Winternitz chain) */
#define SPX_OFFSET_TREE_HGT  27  /* The byte used to specify the height of this node in the FORS or Merkle tree */
#define SPX_OFFSET_TREE_INDEX 28 /* The start of the 4 byte field used to specify the node in the FORS or Merkle tree */

#define SPX_SHAKE 1

#endif /* SHAKE_OFFSETS_H_ */
