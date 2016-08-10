#include "ltfat.h"
#include "ltfat/types.h"
#include "ltfat/macros.h"

struct LTFAT_NAME(idgt_fb_plan)
{
    ltfatInt a;
    ltfatInt M;
    ltfatInt gl;
    ltfat_phaseconvention ptype;
    LTFAT_COMPLEX* cbuf;
    LTFAT_TYPE*    gw;
    LTFAT_COMPLEX* ff;
    LTFAT_FFTW(plan) p_small;
};

#define THE_SUM { \
    memcpy(cbuf,cin+n*M+w*M*N,M*sizeof*cbuf); \
    LTFAT_FFTW(execute)(p->p_small); \
    LTFAT_NAME_COMPLEX(circshift)(cbuf,M,p->ptype?glh:-n*a+glh,ff); \
    LTFAT_NAME_COMPLEX(periodize_array)(ff,M,gl,ff); \
    for (ltfatInt ii=0; ii<gl; ii++) \
        ff[ii] *= gw[ii]; \
}

LTFAT_EXTERN int
LTFAT_NAME(idgt_fb)(const LTFAT_COMPLEX* cin, const LTFAT_TYPE* g,
                    const ltfatInt L, const ltfatInt gl, const ltfatInt W,
                    const ltfatInt a, const ltfatInt M,
                    const ltfat_phaseconvention ptype, LTFAT_COMPLEX* f)

{
    LTFAT_NAME(idgt_fb_plan)* plan = NULL;
    int status = LTFATERR_SUCCESS;

    CHECKSTATUS(
        LTFAT_NAME(idgt_fb_init)(g, gl, a, M, ptype, FFTW_ESTIMATE, &plan),
        "Init failed");

    CHECKSTATUS(
        LTFAT_NAME(idgt_fb_execute)(plan, cin, L, W, f),
        "Execute failed");

error:
    if (plan) LTFAT_NAME(idgt_fb_done)(&plan);
    return status;
}

LTFAT_EXTERN int
LTFAT_NAME(idgt_fb_init)(const LTFAT_TYPE* g, const ltfatInt gl,
                         const ltfatInt a, const ltfatInt M, const ltfat_phaseconvention ptype,
                         unsigned flags, LTFAT_NAME(idgt_fb_plan)** pout)
{
    LTFAT_NAME(idgt_fb_plan)* p = NULL;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(g); CHECKNULL(pout);
    CHECK(LTFATERR_NOTPOSARG, gl > 0, "gl (passed %d) must be positive.", gl);
    CHECK(LTFATERR_NOTPOSARG, a > 0, "a (passed %d) must be positive.", a);
    CHECK(LTFATERR_NOTPOSARG, M > 0, "M (passed %d) must be positive.", M);

    CHECKMEM(p = (LTFAT_NAME(idgt_fb_plan)*)ltfat_calloc(1, sizeof * p));

    p->ptype = ptype;
    p->a = a;
    p->M = M;
    p->gl = gl;

    CHECKMEM( p->cbuf  = LTFAT_NAME_COMPLEX(malloc)(M));
    CHECKMEM( p->gw    = LTFAT_NAME(malloc)(gl));
    CHECKMEM( p->ff    = LTFAT_NAME_COMPLEX(malloc)(gl > M ? gl : M));

    /* Create plan. In-place. */
    p->p_small = LTFAT_FFTW(plan_dft_1d)(M, (LTFAT_FFTW(complex)*) p->cbuf,
                                         (LTFAT_FFTW(complex)*) p->cbuf,
                                         FFTW_BACKWARD, flags);

    CHECKINIT(p->p_small, "FFTW plan failed.");

    LTFAT_NAME(fftshift)(g, gl, p->gw);

    *pout = p;
    return status;
error:
    if (p)
    {
        LTFAT_SAFEFREEALL(p->cbuf, p->gw, p->ff);
        LTFAT_FFTW(destroy_plan)(p->p_small);
        ltfat_free(p);
    }
    return status;
}

LTFAT_EXTERN int
LTFAT_NAME(idgt_fb_execute)(LTFAT_NAME(idgt_fb_plan)* p,
                            const LTFAT_COMPLEX* cin,
                            const ltfatInt L, const ltfatInt W, LTFAT_COMPLEX* f)
{
    ltfatInt M, a, gl, N, ep, sp, glh, glh_d_a;
    LTFAT_COMPLEX* cbuf, *ff;
    LTFAT_TYPE* gw;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(cin); CHECKNULL(f);
    CHECK(LTFATERR_BADARG, L >= p->gl && !(L % p->a) ,
          "L (passed %d) must be positive and divisible by a (passed %d).", L, p->a);
    CHECK(LTFATERR_NOTPOSARG, W > 0, "W (passed %d) must be positive.", W);

    M = p->M;
    a = p->a;
    gl = p->gl;
    N = L / a;

    /* This is a floor operation. */
    glh = gl / 2;

    /* This is a ceil operation. */
    glh_d_a = (ltfatInt)ceil((glh * 1.0) / (a));

    cbuf = p->cbuf;
    gw = p->gw;
    ff = p->ff;

    memset(f, 0, L * W * sizeof * f);

    for (ltfatInt w = 0; w < W; w++)
    {
        LTFAT_COMPLEX* fw = f + w * L;
        /* ----- Handle the first boundary using periodic boundary conditions. --- */
        for (ltfatInt n = 0; n < glh_d_a; n++)
        {
            THE_SUM;

            sp = ltfat_positiverem(n * a - glh, L);
            ep = ltfat_positiverem(n * a - glh + gl - 1, L);

            /* % Add the ff vector to f at position sp. */
            for (ltfatInt ii = 0; ii < L - sp; ii++)
                fw[sp + ii] += ff[ii];

            for (ltfatInt ii = 0; ii < ep + 1; ii++)
                fw[ii] += ff[L - sp + ii];
        }


        /* ----- Handle the middle case. --------------------- */
        for (ltfatInt n = glh_d_a; n < (L - (gl + 1) / 2) / a + 1; n++)
        {
            THE_SUM;

            sp = ltfat_positiverem(n * a - glh, L);
            ep = ltfat_positiverem(n * a - glh + gl - 1, L);

            /* Add the ff vector to f at position sp. */
            for (ltfatInt ii = 0; ii < ep - sp + 1; ii++)
                fw[ii + sp] += ff[ii];
        }

        /* Handle the last boundary using periodic boundary conditions. */
        for (ltfatInt n = (L - (gl + 1) / 2) / a + 1; n < N; n++)
        {
            THE_SUM;

            sp = ltfat_positiverem(n * a - glh, L);
            ep = ltfat_positiverem(n * a - glh + gl - 1, L);

            /* Add the ff vector to f at position sp. */
            for (ltfatInt ii = 0; ii < L - sp; ii++)
                fw[sp + ii] += ff[ii];

            for (ltfatInt ii = 0; ii < ep + 1; ii++)
                fw[ii] += ff[L - sp + ii];
        }
    }

error:
    return status;
}

LTFAT_EXTERN int
LTFAT_NAME(idgt_fb_done)(LTFAT_NAME(idgt_fb_plan)** p)
{
    LTFAT_NAME(idgt_fb_plan)* pp;
    int status = LTFATERR_SUCCESS;
    CHECKNULL(p); CHECKNULL(*p);
    pp = *p;
    LTFAT_SAFEFREEALL(pp->cbuf, pp->ff, pp->gw);
    LTFAT_FFTW(destroy_plan)(pp->p_small);
    ltfat_free(pp);
    pp = NULL;
error:
    return status;
}
