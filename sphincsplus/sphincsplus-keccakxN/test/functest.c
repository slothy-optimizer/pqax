#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../api.h"
#include "../randombytes.h"
#include "../params.h"

#define SPX_MLEN 32
#define NTESTS 10
int main()
{

    unsigned char pk[SPX_PK_BYTES];
    unsigned char sk[SPX_SK_BYTES];
    unsigned char *m = malloc(SPX_MLEN);
    unsigned char *sm = malloc(SPX_BYTES + SPX_MLEN);
    unsigned char *mout = malloc(SPX_BYTES + SPX_MLEN);

    unsigned long long smlen;
    unsigned long long moutlen;
    int rc;
    printf("Parameters: n = %d, h = %d, d = %d, b = %d, k = %d, w = %d, way=%d, tree height=%d, wots_len=%d\n",
           SPX_N, SPX_FULL_HEIGHT, SPX_D, SPX_FORS_HEIGHT, SPX_FORS_TREES,
           SPX_WOTS_W, KECCAK_WAY,SPX_TREE_HEIGHT, SPX_WOTS_LEN );


    for(int i=0;i<NTESTS;i++){
        crypto_sign_keypair(pk, sk);
        randombytes(m, SPX_MLEN);
        crypto_sign(sm, &smlen, m, SPX_MLEN, sk);

        rc = crypto_sign_open(mout, &moutlen, sm, smlen, pk);
        if(rc || memcmp(m, mout, SPX_MLEN)){
            printf("ERROR\n");
        } else {
            printf("OK - signature verified correctly\n");
        }
    }
}