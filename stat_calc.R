library(tidyverse)
library(readxl)
library(gt)
library(fs)
library(here)
library(lubridate)
library(ggsci)
library(gtsummary)
library(magrittr)
library(scales)

create_dataset <- function(dir_name) {
    dir_ls(
        path = here(dir_name),
        glob = "*.csv"
    ) %>% # "Raw_data/sample_date" ディレクトリ内に含まれる.fcsファイルを検索
    path_file() %>% # 生データのファイル名を取得
    tibble(filename = .) %>% # 生データのファイル名をtibble化
    mutate(
        contents = map(
            filename,
            ~ read_csv(here(dir_name, .))
        )
    ) %>%
    unnest(contents) %>%
    mutate(filename = dir_name) %>% # 拡張子削除
    rename("BG" = filename) %T>%
    write_csv(
        file = paste0(here(dir_name), ".csv")
    ) # 一応データをcsvで保存
}

create_dataset("BG(-)")
create_dataset("BG(+)")

df <- read_csv("BG(-).csv")
df2 <- df %>% add_row(read_csv("BG(+).csv"))

    scientific_10 <- function(x) {
        index_zero <- which(x == 0) 
        label <- scientific_format()(x)
        label <- str_replace(label, "e", " %*% 10^")
        label <- str_replace(label, "\\^\\+", "\\^")
        label[index_zero] <- "0"
        parse(text=label)
    }

my_theme_article_single_column <- theme_classic() + # 装飾を全部なくす
    theme(
        legend.title = element_text(colour = "black", size = 7, face = "bold"), # 凡例タイトルの文字サイズ
        legend.text = element_text(colour = "black", size = 7), #凡例テキストのサイズ
        panel.border = element_blank(), 
        axis.ticks = element_line(colour = "black", size = 0.5) , # 軸の色&太さ
        axis.ticks.length = unit(1, "mm"), # 軸目盛の長さ
        axis.title = element_text(colour = "black", size = 7, face = "bold"),
        axis.text.x = element_text(colour = "black", size = 7, face = "bold"), 
        axis.text.y = element_text(colour = "black", size = 7, face = "bold"), #軸のフォントの色
        axis.line = element_line(colour = "black", size = 0.5, lineend = "square") ,   #軸の太さ(size = 1とか指定)と色の指定
        title = element_text(colour = "black", size = rel(0.5), face = "bold"),
        strip.text.x = element_text(size = 7, face = "bold"),
        strip.background = element_blank(),
    )

df2 %>%
    ggplot(aes(Radius_μm, fill = BG)) +
    geom_histogram(
        aes(y=100*(..count..)/sum(..count..)),
        alpha = 0.4,
        position = "identity",
        lwd = 0.2
        ) +
    geom_density(aes(y=4*..density.., colour = BG), stat="density", alpha = 0, size = 0.5) +
    my_theme_article_single_column +
    scale_x_log10(
        limits = c(0.5, 50),
        breaks = c(0.5, 1, 5, 10, 50),
        labels = scales::number_format(accuracy = 0.1)
        ) +
    scale_y_continuous(
        limits = c(0, NA),
        labels = scales::number_format(accuracy = 0.1)
        ) +
    xlab("Diameter (μm)") +
    ylab("Normlized particle count(%)") +
    scale_color_jco() +
    scale_fill_jco() +
    annotation_logticks(
    sides = "b",
    long = unit(0.2, "cm"),
    mid = unit(0.1, "cm"),
    short = unit(0.05, "cm")
    )


df_summary <-
    df2 %>%
    group_by(BG) %>%
    summarise(
        mean = mean(Radius_μm),
        sd = sd(Radius_μm)
        ) %>%
        mutate(
    cv = sd*100/mean
    ) %>%
    write_csv("before_extruder_CV.csv")


ggsave(
    here(paste0(today(), "_Fig@@.png")),
    width = 12,
    height = 7,
    dpi = 320,
    units = "cm"
    )
