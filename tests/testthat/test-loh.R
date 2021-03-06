test_that("HR-LOH score works - simple cases", {
  cov <- GRanges(seqnames = factor(c(paste0(1:4, 'p'), paste0(1:4, 'q')),
                                   levels = c(paste0(1:4, 'p'), paste0(1:4, 'q'))),
                 ranges = IRanges(start = rep(1, 8),
                                  end = rep(200*10^6, 8)))
  segs <- GRanges(seqnames = factor(c(rep('1p', 6), rep('2p', 2)), levels = paste0(1:4, 'p')),
                  ranges = IRanges(start = c( 1, 10, 40, 60-0.000001, 80, 100,  1, 50)*10^6 + 1,
                                   end =   c(10, 30, 55, 75,        95, 120, 20, 80)*10^6),
                  cn = c(NA, NA, NA, NA, 3, 1, NA, 15),
                  cn.type = c(cntype.loh, cntype.loh, cntype.loh, cntype.loh,
                              cntype.gain, cntype.loss, cntype.loh, cntype.gain),
                  cn.subtype = c(cntype.loh, cntype.loh, cntype.loh, cntype.loh,
                                 cntype.gain, cntype.hetloss, cntype.loh, cntype.strongamp))
  n <- score_loh(segs, cov, c('2p', '2q'), c())
  expect_equal(n, 3)
})

test_that("HR-LOH score works - chrom with LOH and hetloss", {
  cov <- GRanges(seqnames = factor(c(paste0(1:4, 'p'), paste0(1:4, 'q')),
                                   levels = c(paste0(1:4, 'p'), paste0(1:4, 'q'))),
                 ranges = IRanges(start = rep(1, 8),
                                  end = rep(200*10^6, 8)))
  segs <- GRanges(seqnames = factor(c(rep('1p', 6), rep('2p', 2)), levels = paste0(1:4, 'p')),
                  ranges = IRanges(start = c( 1, 10, 40, 60-0.000001, 80, 100,  1, 50)*10^6 + 1,
                                   end =   c(10, 30, 55, 75,        95, 120, 20, 80)*10^6),
                  cn = c(NA, NA, NA, NA, 3, 1, NA, 15),
                  cn.type = c(cntype.loh, cntype.loh, cntype.loh, cntype.loh,
                              cntype.gain, cntype.loss, cntype.loh, cntype.gain),
                  cn.subtype = c(cntype.loh, cntype.loh, cntype.loh, cntype.loh,
                                 cntype.gain, cntype.hetloss, cntype.loh, cntype.strongamp))
  n <- score_loh(segs, cov, c('2p'), c('2q'))
  expect_equal(n, 4)
})


test_that("HR-LOH score works - overlapping loh", {
  cov <- GRanges(seqnames = factor(c(paste0(1:4, 'p'), paste0(1:4, 'q')),
                                   levels = c(paste0(1:4, 'p'), paste0(1:4, 'q'))),
                 ranges = IRanges(start = rep(1, 8),
                                  end = rep(200*10^6, 8)))
  segs <- GRanges(seqnames = factor(c(rep('1p', 6), rep('2p', 2)), levels = paste0(1:4, 'p')),
                  ranges = IRanges(start = c( 1, 10, 40, 60-0.000001, 80, 100,  1, 50)*10^6 + 1,
                                   end =   c(10, 20, 55, 75,        95, 120, 20, 80)*10^6),
                  cn = c(NA, NA, NA, NA, 3, 1, NA, 15),
                  cn.type = c(cntype.loh, cntype.loh, cntype.loh, cntype.loh,
                              cntype.gain, cntype.loss, cntype.loh, cntype.gain),
                  cn.subtype = c(cntype.loh, cntype.loh, cntype.loh, cntype.loh,
                                 cntype.gain, cntype.hetloss, cntype.loh, cntype.strongamp))
  n <- score_loh(segs, cov, c(), c())
  expect_equal(n, 4)
})

test_that("LOH works - real case", {
  oncoscan.cov <- oncoscanR::oncoscan_na33.cov[seqnames(oncoscanR::oncoscan_na33.cov) != '21p']

  chas.fn <- system.file("testdata", "LST_gene_list_full_location.txt", package = "oncoscanR")
  segments <- load_chas(chas.fn, oncoscan.cov)
  segments$cn.subtype <- get_cn_subtype(segments, 'F')
  segs.clean <- trim_to_coverage(segments, oncoscan.cov) %>%
    adjust_loh() %>%
    prune_by_size()

  armlevel.loh <- segs.clean[segs.clean$cn.type == cntype.loh] %>%
    armlevel_alt(kit.coverage = oncoscan.cov)
  armlevel.hetloss <- segs.clean[segs.clean$cn.subtype == cntype.hetloss] %>%
    armlevel_alt(kit.coverage = oncoscan.cov)

  n <- score_loh(segs.clean, oncoscan.cov, names(armlevel.loh), names(armlevel.hetloss))
  expect_equal(n, 25) #Verified by hand in ChAS
})

test_that("LOH works - empty segments", {
  cov <- GRanges(seqnames = factor(paste0(1:4, 'p'), levels = paste0(1:4, 'p')),
                 ranges = IRanges(start = c(1,1,101,101),
                                  end = c(100,100,200,200)))
  segs <- GRanges(seqnames = factor(c(), levels = paste0(1:4, 'p')),
                  ranges = IRanges())
  n <- score_loh(segs, cov, c(), c())
  expect_equal(n, 0)
})

