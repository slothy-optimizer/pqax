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

#include <string.h>

#include "utils.h"
#include "utilsx.h"
#include "params.h"
#include "thashx.h"
#include "thash.h"
#include "address.h"

// TODO: update docu
/*
 * Generate the entire Merkle tree, computing the authentication path for leaf_idx,
 * and the resulting root node using Merkle's TreeHash algorithm.
 * Expects the layer and tree parts of the tree_addr to be set, as well as the
 * tree type (i.e. SPX_ADDR_TYPE_HASHTREE or SPX_ADDR_TYPE_FORSTREE)
 *
 * This expects tree_addrx4 to be initialized to 4 parallel addr structures for
 * the Merkle tree nodes
 *
 * Applies the offset idx_offset to indices before building addresses, so that
 * it is possible to continue counting indices across trees.
 *
 * This works by using the standard Merkle tree building algorithm, except
 * that each 'node' tracked is actually 4 consecutive nodes in the real tree.
 * When we combine two logical nodes ABCD and WXYZ, we perform the H
 * operation on adjacent real nodes, forming the parent logical node
 * (AB)(CD)(WX)(YZ)
 *
 * When we get to the top two levels of the real tree (where there is only
 * one logical node), we continue this operation two more times; the right
 * most real node will by the actual root (and the other 3 nodes will be
 * garbage).  We follow the same thashx4 logic so that the 'extract
 * authentication path components' part of the loop is still executed (and
 * to simplify the code somewhat)
 *
 * This currently assumes tree_height >= 2; I suspect that doing an adjusting
 * idx, addr_idx on the gen_leafx4 call if tree_height < 2 would fix it; since
 * we don't actually use such short trees, I haven't bothered
 */
void treehashx(unsigned char *root, unsigned char *auth_path,
                const spx_ctx *ctx,
                uint32_t leaf_idx, uint32_t idx_offset,
                uint32_t tree_height,
                void (*gen_leafx)(
                   unsigned char* /* Where to write the leaves */,
                   const spx_ctx*,
                   uint32_t idx, void *info),
                uint32_t tree_addr[8],
                void *info)
{

    #if KECCAK_WAY == 4
    unsigned int i,j;
    /* This is where we keep the intermediate nodes */
    unsigned char stackx4[tree_height*4*SPX_N];


    unsigned char *in[4];
    unsigned char *out[4];
    uint32_t left_adj = 0, prev_left_adj = 0; /* When we're doing the top 3 */
        /* levels, the left-most part of the tree isn't at the beginning */
        /* of current[].  These give the offset of the actual start */

    uint32_t idx;
    uint32_t max_idx = (1 << (tree_height-2)) - 1;

    uint32_t tree_addrx4[4*8];
    for(i=0;i<8;i++){
        for(j=0;j<4;j++){
            tree_addrx4[j*8+i] = tree_addr[i];
        }
    }


    for (idx = 0;; idx++) {
        unsigned char current[4*SPX_N];   /* Current logical node */
        gen_leafx( current, ctx, 4*idx + idx_offset,
                    info );

        /* Now combine the freshly generated right node with previously */
        /* generated left ones */
        uint32_t internal_idx_offset = idx_offset;
        uint32_t internal_idx = idx;
        uint32_t internal_leaf = leaf_idx;
        uint32_t h;     /* The height we are in the Merkle tree */
        for (h=0;; h++, internal_idx >>= 1, internal_leaf >>= 1) {

            /* Special processing if we're at the top of the tree */
            if (h >= tree_height - 2) {
                if (h == tree_height) {
                    /* We hit the root; return it */
                    memcpy( root, &current[3*SPX_N], SPX_N );
                    return;
                }
                /* The tree indexing logic is a bit off in this case */
                /* Adjust it so that the left-most node of the part of */
                /* the tree that we're processing has index 0 */
                prev_left_adj = left_adj;
                left_adj = 4 - (1 << (tree_height - h - 1));
            }

            /* Check if we hit the top of the tree */
            if (h == tree_height) {
                /* We hit the root; return it */
                memcpy( root, &current[3*SPX_N], SPX_N );
                return;
            }

            /*
             * Check if one of the nodes we have is a part of the
             * authentication path; if it is, write it out
             */
            if ((((internal_idx << 2) ^ internal_leaf) & ~0x3) == 0) {
                memcpy( &auth_path[ h * SPX_N ],
                        &current[(((internal_leaf&3)^1) + prev_left_adj) * SPX_N],
                        SPX_N );
            }

            /*
             * Check if we're at a left child; if so, stop going up the stack
             * Exception: if we've reached the end of the tree, keep on going
             * (so we combine the last 4 nodes into the one root node in two
             * more iterations)
             */
            if ((internal_idx & 1) == 0 && idx < max_idx) {
                break;
            }

            /* Ok, we're at a right node (or doing the top 3 levels) */
            /* Now combine the left and right logical nodes together */

            /* Set the address of the node we're creating. */
            int j;
            internal_idx_offset >>= 1;
            for (j = 0; j < 4; j++) {
                set_tree_height(tree_addrx4 + j*8, h + 1);
                set_tree_index(tree_addrx4 + j*8,
                     (4/2) * (internal_idx&~1) + j - left_adj + internal_idx_offset );
            }
            // unsigned char *left = &stackx4[h * 4 * SPX_N];
            // thashx4( &current[0 * SPX_N],
            //          &current[1 * SPX_N],
            //          &current[2 * SPX_N],
            //          &current[3 * SPX_N],
            //          &left   [0 * SPX_N],
            //          &left   [2 * SPX_N],
            //          &current[0 * SPX_N],
            //          &current[2 * SPX_N],
            //          2, ctx, tree_addrx4);

            in[0] = &stackx4[h * 4 * SPX_N];
            in[1] = &stackx4[h * 4 * SPX_N + 2*SPX_N];
            in[2] = &current[0 * SPX_N];
            in[3] = &current[2 * SPX_N];

            for(i=0;i<4;i++){
                out[i] = &current[i * SPX_N];
            }

            thashx(out, (const unsigned char**)in, 2, ctx, tree_addrx4);
        }

        /* We've hit a left child; save the current for when we get the */
        /* corresponding right right */
        memcpy( &stackx4[h * 4 * SPX_N], current, 4 * SPX_N);
    }
    #else

    unsigned char current[KECCAK_WAY*SPX_N];
    unsigned int current_idx = KECCAK_WAY;

    // TODO: implement this later properly
    unsigned char stack[(tree_height + 1)*SPX_N];
    unsigned int heights[tree_height + 1];
    unsigned int offset = 0;
    uint32_t idx;
    uint32_t tree_idx;

    for (idx = 0; idx < (uint32_t)(1 << tree_height); idx++) {
        /* Add the next leaf node to the stack. */
        if(current_idx >= KECCAK_WAY){
            gen_leafx(current, ctx, idx + idx_offset, info);
            current_idx = 0;
        }
        memcpy(stack + offset*SPX_N, current + current_idx*SPX_N, SPX_N);


        offset++;
        heights[offset - 1] = 0;

        /* If this is a node we need for the auth path.. */
        if ((leaf_idx ^ 0x1) == idx) {
            memcpy(auth_path, stack + (offset - 1)*SPX_N, SPX_N);
        }

        /* While the top-most nodes are of equal height.. */
        while (offset >= 2 && heights[offset - 1] == heights[offset - 2]) {
            /* Compute index of the new node, in the next layer. */
            tree_idx = (idx >> (heights[offset - 1] + 1));

            /* Set the address of the node we're creating. */
            set_tree_height(tree_addr, heights[offset - 1] + 1);
            set_tree_index(tree_addr, tree_idx + (idx_offset >> (heights[offset-1] + 1)));
            /* Hash the top-most nodes from the stack together. */
            thash(stack + (offset - 2)*SPX_N,
                  stack + (offset - 2)*SPX_N, 2, ctx, tree_addr);
            offset--;
            /* Note that the top-most node is now one layer higher. */
            heights[offset - 1]++;

            /* If this is a node we need for the auth path.. */
            if (((leaf_idx >> heights[offset - 1]) ^ 0x1) == tree_idx) {
                memcpy(auth_path + heights[offset - 1]*SPX_N,
                       stack + (offset - 1)*SPX_N, SPX_N);
            }
        }
        current_idx++;
    }
    memcpy(root, stack, SPX_N);

    #endif
}
