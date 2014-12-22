library(downloader)
library(plyr)
library(dplyr)

download("https://raw.githubusercontent.com/jennybc/lotr/master/lotr_clean.tsv",
				 "lotr_clean.tsv")

lotr <- read.delim("lotr_clean.tsv", stringsAsFactors = FALSE)

fotr <- lotr %>% filter(Film == "The Fellowship Of The Ring")

fake_dat <- ddply(fotr, ~ Character + Film + Race,
									summarize, words = sum(Words)) %>%
	arrange(desc(words)) %>%
	mutate(mark = (100 * (min_rank(words) / length(words)))  %>% round) %>%
	select(name = Character, mark, Race)

email_domains <-
	read.csv(text = c("Race, domain",
										"Hobbit, shire",
										"Elf, valinor",
										"Wizard, maiar",
										"Man, gondor",
										"Orc, mordor",
										"Dwarf, erebor"),
					 strip.white = TRUE, stringsAsFactors = FALSE)

fake_dat <- fake_dat %>%
	left_join(email_domains) %>%
	mutate(name_sans_spaces = gsub('[\\.\\s+]+', '_', fake_dat$name, perl = TRUE),
				 email = paste0(tolower(name_sans_spaces), "@", domain, ".org"))

marks <- fake_dat %>%
	select(name, mark)

write.csv(marks, file.path("..", "marks.csv"), row.names = FALSE, quote = FALSE)

emails <- fake_dat %>%
	select(name, email)

write.csv(emails, file.path("..", "addresses.csv"), row.names = FALSE, quote = FALSE)


