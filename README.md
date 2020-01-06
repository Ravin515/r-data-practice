# Answer Keys for [Renkun](https://github.com/renkun-ken)'s R Data Practise
# Overview
This is the keys to [Renkun](https://github.com/renkun-ken)'s [50 R data exercises](https://github.com/renkun-ken/r-data-practice). The original 50 exercises are desiged to help users build a solid skill set for data cleaning/manipulation. [Renkun]((https://github.com/renkun-ken)) didn't provide keys to these exercises and here we present ours using the `data.table` package. We believe `data.table` is the BEST R tool for data manipulation. For more information about how amazing `data.table` is, please refer to its [Github page](https://github.com/Rdatatable/data.table). 

The 50 exercises are built on a stock price dataset including variables like `symbol`, `date` and `price`. These exercises include common data manipulation practise like *compute the average for the largest N observations within each group* or *find out the top N stocks with the largest price jump during the past M days*. 

# Project Structure
- `dataset-and-questions.md`: Introduction to the dataset and question list (no answer keys included).

- `answer-keys.ipynb`: The questions and answers.![answer-keys](img/answer-keys.png)

- `data`: the data folder
    - `stock-market-data.rds`: the dataset. Please use `readRDS` to import the data.


# R语言数据操作练习
# 概览
本Repo是[Renkun](https://github.com/renkun-ken)50道R数据操作练习题的答案。这些题目旨在帮助用户掌握常见的数据操作，例如*找出每组中最大的N个观测*。这些练习依赖于一个股票价格数据集（包含在本项目中），包含日期、股票代码、价格等变量。

[Renkun](https://github.com/renkun-ken)本没有练习的答案，我们在这里提供了使用`data.table`的实现。我们认为`data.table`是最好的R数据处理工具包，关于更多`data.table`的神奇之处，请参考它的[Github 主页](https://github.com/Rdatatable/data.table)

## 项目结构
- `dataset-and-questions.md`： 关于数据集的介绍，同时给出所有50道练习题（不含答案）。

- `answer-keys.ipynb`: 练习题答案。每一道练习题都包括题目、答案代码以及答案预览
![answer-keys](img/answer-keys.png)


## 学习资源推荐

* [Base R cheatsheet](http://github.com/rstudio/cheatsheets/raw/master/base-r.pdf)
* [RStudio IDE cheatsheet](https://github.com/rstudio/cheatsheets/raw/master/rstudio-ide.pdf)
* [Regular Expressions](https://www.rstudio.com/wp-content/uploads/2016/09/RegExCheatsheet.pdf)
* [Work with Strings cheatsheet](https://github.com/rstudio/cheatsheets/raw/master/strings.pdf)
* [data.table cheatsheet](https://github.com/rstudio/cheatsheets/raw/master/datatable.pdf)

## 更多
如果希望了解更多R相关的技巧，欢迎订阅我们的公众号：`大猫的R语言课堂`。
