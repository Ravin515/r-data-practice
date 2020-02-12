library(data.table)
library(tidyverse)
library(microbenchmark)
stock_data <- readRDS("r-data-practice-master/data/stock-market-data.rds")
head(stock_data)


# 1. 哪些股票的代码中包含"8"这个数字？ ---------------------------------------------------

library(stringr)
microbenchmark(
  stock_data$symbol[str_detect(stock_data$symbol, "8")] %>% unique(),
  stock_data[str_detect(symbol, "8"), unique(symbol)]
  )

# 2. 每天上涨和下跌的股票各有多少？ ---------------------------------------------------------

microbenchmark(
  stock_data[,
     .(num = uniqueN(symbol)),
     keyby = .(date, UpDown = ifelse(pre_close > close, "Down", "Up"))],
  times = 5)
microbenchmark(
  stock_data %>% 
    mutate(UpDown = ifelse(pre_close > close, "Down", "Up")) %>%
    group_by(date, UpDown) %>%
    summarise(num = n()),
  times = 5)

# 3. 每天每个交易所上涨、下跌的股票各有多少？ ----------------------------------------------------

microbenchmark(
stock_data[,
           .(num = uniqueN(symbol)),
           keyby = .(date,
                     exchange = str_sub(symbol, start = -2, end = -1),
                     UpDown = ifelse(pre_close > close, "Down", "Up"))],
times = 5)
microbenchmark(
stock_data %>%
  mutate(exchange = str_sub(symbol, start = -2, end = -1), UpDown = ifelse(pre_close > close, "Down", "Up")) %>%
  group_by(date, exchange) %>%
  summarise(num = n()),
times = 5)

# 4. 沪深300成分股中，每天上涨、下跌的股票各有多少？ --------------------------------------------

microbenchmark(
filter(stock_data, index_w300 > 0) %>%
  mutate(UpDown = ifelse(pre_close > close, "Down", "Up")) %>%
  group_by(date, UpDown) %>%
  summarise(num = n()),
times = 5)
microbenchmark(
stock_data[index_w300 > 0, 
     .(num = uniqueN(symbol)), 
     keyby = .(date, updown = ifelse(close - pre_close > 0, "UP", "DOWN"))
     ][1:5],
times = 5)

# 5. 每天每个行业各有多少只股票？ -------------------------------------------------------

stock_data %>%
  group_by(date, industry) %>%
  summarise(num = n())
data[, .(stk_num = uniqueN(symbol)), 
     keyby = .(date, industry)
     ][1:5]

# 6. 股票数最大的行业和总成交额最大的行业是否总是同一个行业？ -----------------------------------------

microbenchmark(
stock_data %>%
  group_by(date, industry) %>%
  summarise(trd_amount = sum(amount), stk_num = uniqueN(symbol)) %>%
  group_by(date) %>%
  filter(rank(desc(trd_amount)) == 1 & rank(desc(stk_num)) == 1),
times = 5)
microbenchmark(
stock_data[, .(trd_amount = sum(amount), stk_num = uniqueN(symbol)), keyby = .(date, industry)
     ][, .SD[trd_amount == max(trd_amount) & stk_num == max(stk_num), .(industry)], 
       keyby = .(date)
       ][1:5],
times = 5)

# 7. 每天涨幅超过5%、跌幅超过5%的股票各有多少？ ----------------------------------------------

microbenchmark(
stock_data %>%
  mutate(ret = (close - pre_close)/pre_close) %>%
  group_by(date) %>%
  summarise(high_up = sum(ret > 0.05), high_down = sum(ret < -0.05)),
times = 5)
microbenchmark(
stock_data[, ':='(ret = (close - pre_close)/pre_close),
     ][ret > 0.05 | ret < -0.05, 
       .(symbol_amount = uniqueN(symbol)), 
       keyby = .(date, updown = ifelse(ret > 0.05, "up5%+", "down5%+"))
       ][1:5],
times = 5)

# 8. 每天涨幅前10的股票的总成交额和跌幅前10的股票的总成交额比例是多少？ ----------------------------------

microbenchmark(
stock_data %>%
  mutate(ret = (close - pre_close)/pre_close) %>%
  group_by(date) %>%
  summarise(top10 = sum(amount[rank(desc(ret)) <= 10]),
            bottom10 = sum(amount[rank(ret) <= 10]),
            ratio = bottom10/top10),
times = 5)
microbenchmark(
stock_data[, ':='(ret = (close - pre_close)/pre_close)
     ][order(date, ret)
       ][, .(top10 = sum(amount[1:10]), bottom10 = sum(amount[(.N - 10):.N])),
         keyby = date
         ][, ':='(ratio = top10/bottom10)
           ][1:15],
times = 5)

# 9. 每天开盘涨停的股票与收盘涨停的股票各有多少？ -----------------------------------------------

microbenchmark(
stock_data %>%
  mutate(ret_open = open/pre_close - 1, ret_close = close/pre_close - 1) %>%
  group_by(date) %>%
  summarise(n_openlimit = sum(ret_open > 0.015),
            n_closelimit = sum(ret_close > 0.015)),
times = 5)
microbenchmark(
  stock_data[, ':='(ret_open = open/pre_close - 1, 
              ret_close = close/pre_close - 1)
       ][, .(n_openlimit = sum(ret_open > 0.015),
             n_closelimit = sum(ret_close > 0.015)),
         keyby = date
         ][1:5],
times = 5)

# 10. 每天统计最近3天出现过开盘涨停的股票各有多少只？ --------------------------------------------

microbenchmark(
{df10 <- stock_data %>%
  mutate(n_openlimit = ifelse(open/pre_close > 1.015, 1, 0)) %>%
  group_by(date) %>%
  summarise(num = sum(n_openlimit),
            n_openlimit_3d = NA)
for (i in 4:length(unique(stock_data$date))) {
    df10$n_openlimit_3d[[i]] <- sum(df10$num[(i - 3):(i - 1)])
}}, times = 5)

microbenchmark(
{data_ex9 <- stock_data[, ':='(ret_open = open/pre_close - 1, 
                        ret_close = close/pre_close - 1)
                 ][, .(n_openlimit = sum(ret_open > 0.015),
                       n_closelimit = sum(ret_close > 0.015)),
                   keyby = date]
data_ex9[, 
         .(date, 
           n_openlimit_3d = {
             l = vector()
             for (t in 4:.N) {
               l[t] = sum(n_openlimit[(t - 3):(t - 1)])
             }
             l
           })
         ][1:5]
}, times = 5)

# 11. 股票每天的成交额变化率和收益率的相关性如何？ ----------------------------------------------

microbenchmark(
stock_data[,
    .(amount_change = {
    a <- vector()
    for (i in 2:.N) {a[i] <- amount[i]/amount[i - 1] - 1}
    a}, 
    ret = close/pre_close - 1, symbol = symbol)
    ][is.finite(amount_change), na.omit(.SD)
    ][, cor(amount_change, ret)],
times = 10)

microbenchmark(
stock_data %>% 
  mutate(amount_change = {
         a <- vector()
         for (i in 2:dim(stock_data)[1]) {a[i] <- amount[i]/amount[i - 1] - 1}
       a}, ret = close/pre_close - 1) %>% 
  select(amount_change, ret) %>% 
  filter(is.finite(amount_change) == T, is.na(ret) == F, is.na(amount_change) == F) %>%
  cor(),
times = 10)

# 12. 每天每个行业的总成交额变化率和行业收益率的相关性如何？ -----------------------------------------

df12 <- stock_data %>%
  mutate(ret = close/pre_close - 1) %>%
  group_by(industry, date) %>%
  summarise(ind_amount = sum(amount),
            ind_ret = weighted.mean(ret, w = capt)) %>%
  mutate(ind_amount_change = {
    a <- vector()
    for (i in 2:length(ind_ret)) {a[i] <- ind_amount[i]/ind_amount[i - 1] - 1}
    a})
cor(df12$ind_ret, df12$ind_amount_change, use = "complete.obs")

stock_data[, .(ind_amount = sum(amount), weight = capt/sum(capt), ret = close/pre_close - 1), keyby = .(date, industry)
     ][, .(ind_ret = sum(weight * ret), ind_amount = ind_amount), keyby = .(industry, date)
     ][, unique(.SD)
     ][, .(ind_amount_change = {
         a <- vector()
         for (i in 2:.N) {
             a[i] <- ind_amount[i]/ind_amount[i - 1] - 1
         }
         a
     }, ind_ret = ind_ret), keyby = .(industry)
     ][!is.na(ind_amount_change), cor(ind_amount_change, ind_ret)]

# 13. 每天市场的总成交额变化率和市场收益率相关性如何？ --------------------------------------------

df13 <- stock_data %>%
  mutate(ret = close/pre_close - 1) %>%
  group_by(date) %>%
  summarise(mkt_amount = sum(amount),
            mkt_ret = weighted.mean(ret, w = capt)) %>%
  mutate(mkt_amount_change = {
    a <- vector()
    for (i in 2:length(date)) {a[i] <- mkt_amount[i]/mkt_amount[i - 1] - 1}
    a})
cor(df13$mkt_ret, df13$mkt_amount_change, use = "complete.obs")

data[, .(mkt_amount = sum(amount), weight = capt/sum(capt), ret = close/pre_close - 1), keyby = date
     ][, .(mkt_ret = sum(weight * ret), mkt_amount = mkt_amount), keyby = date
     ][, unique(.SD)
     ][, .(mkt_amount_change = {
         a <- vector()
         for (i in 2:.N) {a[i] <- mkt_amount[i]/mkt_amount[i - 1] - 1
         }
         a
     }, mkt_ret = mkt_ret)
     ][!is.na(mkt_amount_change), cor(mkt_amount_change, mkt_ret)]

# 14. 每天市场的总成交额的变化率和所有股票收益率的标准差相关性如何？ -------------------------------------

df14 <- stock_data %>%
  mutate(ret = close/pre_close - 1) %>%
  group_by(date) %>%
  summarise(mkt_amount = sum(amount),
            ret_sd = sd(ret)) %>%
  mutate(mkt_amount_change = {
    a <- vector()
    for (i in 2:length(date)) {a[i] <- mkt_amount[i]/mkt_amount[i - 1] - 1}
    a})
cor(df14$ret_sd, df14$mkt_amount_change, use = "complete.obs")

data[, .(mkt_amount = sum(amount), ret = close/pre_close - 1, symbol = symbol), keyby = date
     ][, .(ret_sd = unique(sd(ret)), mkt_amount = unique(mkt_amount)), keyby = date
     ][, .(mkt_amount_change = {
         a <- vector()
         for (i in 2:.N) {a[i] <- mkt_amount[i]/mkt_amount[i - 1] - 1
         }
         a
     }, ret_sd = ret_sd)
     ][!is.na(mkt_amount_change), cor(mkt_amount_change, ret_sd)]

# 15. 每天每个行业的总成交额变化率和行业内股票收益率的标准差相关性如何？ -----------------------------------

df15 <- stock_data %>%
  mutate(ret = close/pre_close - 1) %>%
  group_by(industry, date) %>%
  summarise(ind_amount = sum(amount),
            ind_ret_sd = sd(ret)) %>%
  mutate(ind_amount_change = {
    a <- vector()
    for (i in 2:length(ind_ret_sd)) {a[i] <- ind_amount[i]/ind_amount[i - 1] - 1}
    a})
cor(df15$ind_ret_sd, df15$ind_amount_change, use = "complete.obs")

data[, .(ind_amount = sum(amount), ret = close/pre_close - 1, symbol = symbol), keyby = .(industry, date)
     ][, .(ind_ret_sd = unique(sd(ret)), ind_amount = unique(ind_amount)), keyby = .(industry, date)
     ][, .(ind_amount_change = {
         a <- vector()
         for (i in 2:.N) {a[i] <- ind_amount[i]/ind_amount[i - 1] - 1
         }
         a
     }, ind_ret_sd = ind_ret_sd), keyby = industry
     ][!is.na(ind_amount_change), cor(ind_ret_sd, ind_amount_change)]

# 16. 上证50、沪深300、中证500指数成分股中，沪股和深股各有多少？ -----------------------------------

stock_data %>%
  mutate(exchange = str_sub(symbol, start = -2, end = -1), 
         index_w50 = ifelse(index_w50 > 0, 1, 0), 
         index_w300 = ifelse(index_w300 > 0, 1, 0), 
         index_w500 = ifelse(index_w500 > 0, 1, 0)) %>%
  group_by(date, exchange) %>%
  summarise(index50 = sum(index_w50),
            index300 = sum(index_w300),
            index500 = sum(index_w500))

stock_data[, melt(.SD, measure.vars = patterns("index"), variable.name = "index_name")
       ][value > 0, .(stkcd_amount = uniqueN(symbol)), 
         by = .(index_name, type = ifelse(str_detect(symbol, "SH"), "SH", "SZ"))]

# 17. 上证50、沪深300、中证500指数成分股中，行业分布如何？ --------------------------------------

microbenchmark(
stock_data %>%
  mutate(index_w50 = ifelse(index_w50 > 0, 1, 0), 
         index_w300 = ifelse(index_w300 > 0, 1, 0), 
         index_w500 = ifelse(index_w500 > 0, 1, 0)) %>%
  group_by(date, industry) %>%
  summarise(index50 = sum(index_w50),
            index300 = sum(index_w300),
            index500 = sum(index_w500)),
times = 10)

microbenchmark(
stock_data[, melt(.SD, measure.vars = patterns("index"), variable.name = "index_name")
     ][value > 0, .(stkcd_amount = uniqueN(symbol)), by = .(index_name, industry)
     ][1:5],
times = 10)

# 18. 每天上证50、沪深300、中证500指数成分股的总成交额各是多少？ -----------------------------------

stock_data %>%
  mutate(index_w50 = ifelse(index_w50 > 0, 1, 0), 
         index_w300 = ifelse(index_w300 > 0, 1, 0), 
         index_w500 = ifelse(index_w500 > 0, 1, 0)) %>%
  group_by(date) %>%
  summarise(index50 = sum(index_w50 * amount),
            index300 = sum(index_w300 * amount),
            index500 = sum(index_w500 * amount))

data[, melt(.SD, measure.vars = patterns("index"), variable.name = "index_name")
     ][value > 0, .(amount = sum(amount)), by = .(index_name, date)
     ][1:5]

# 19. 上证50、沪深300、中证500指数日收益率的历史波动率是多少？ ------------------------------------

df19 <- stock_data %>%
  mutate(ret = close/pre_close - 1) %>%
  group_by(date) %>%
  summarise(index50 = sum(index_w50 * ret),
            index300 = sum(index_w300 * ret),
            index500 = sum(index_w500 * ret))
map_dbl(df19[,2:4], sd)

data[, melt(.SD, measure.vars = patterns("index"), variable.name = "index_name")
     ][, .(index_ret = sum(value * (close/pre_close - 1))), by = .(date, index_name)
     ][, .(vol = sd(index_ret)), by = .(index_name)]

# 20. 上证50、沪深300、中证500指数日收益率的相关系数矩阵？¶ -------------------------------------

cor(df19[2:4])

data[, .(index_w50_ret = sum(index_w50 * (close/pre_close - 1)), 
         index_w300_ret = sum(index_w300 * (close/pre_close - 1)), 
         index_w500_ret = sum(index_w500 * (close/pre_close - 1))), keyby = date
     ][, cor(.SD[, -1])]


# 21. 上证50、沪深300、去除上证50的沪深300指数日收益率的相关系数矩阵？ -------------------------------

df21 <- stock_data %>%
  mutate(ret = close/pre_close - 1,
         index300_50_ret = ifelse(index_w50 > 0, 0, ret * index_w300)) %>%
  group_by(date) %>%
  summarise(index50 = sum(index_w50 * ret),
            index300 = sum(index_w300 * ret),
            index300_50 = sum(index300_50_ret))
cor(df21[2:4])

# 22. 每天沪深300指数成分占比最大的10只股票是哪些？ -------------------------------------------

stock_data %>%
  arrange(date, index_w300) %>%
  group_by(date) %>%
  summarise(Big10 = paste(symbol[1:10], collapse = " "))

stock_data[order(date, index_w300), .(symbol = symbol[1:10]), by = .(date)
     ][1:5]

# 23. 各个行业的平均每日股票数量从大到小排序是什么？ ---------------------------------------------

microbenchmark(
stock_data %>%
  group_by(date) %>%
  count(industry) %>%
  group_by(industry) %>%
  summarise(n = mean(n)) %>%
  arrange(desc(n)),
times = 10)

microbenchmark(
stock_data[, .(stkcd_amount = uniqueN(symbol)), keyby = .(date, industry)
     ][order(date, -stkcd_amount)
     ],
times = 10)

# 24. 每个行业每天成交额最大的一只股票代码是什么？ ----------------------------------------------

stock_data %>%
  arrange(desc(amount)) %>%
  group_by(date, industry) %>%
  summarise(No_1 = symbol[1])

stock_data[order(-amount), .(symbol = symbol[1]), keyby = .(date, industry)
     ][1:5]

# 25. 每个行业每天最大成交额是最小成交额的几倍？ -----------------------------------------------

stock_data %>%
  filter(amount > 0) %>%
  group_by(date, industry) %>%
  summarise(times = max(amount)/min(amount))

stock_data[order(-amount) & amount > 0, .(times = amount[1]/amount[.N]), 
     keyby = .(date, industry)
     ]