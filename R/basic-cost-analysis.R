# Park work totals
#
# Calculating total costs from maintenance and fly tipping since 2013-14

library(readxl)
library(dplyr)
library(ggplot2)
##############################################################
#                        Load data                           #
##############################################################

maint_data <- read_excel(
  "data/park-work-records/maintenance-all-years.xlsx"
  ) %>%
  mutate(
    Type = "Maintenance"
  ) %>%
  select(
    -Play_Park
  )

ft_data <- read_excel(
  "data/park-work-records/fly-tipping-all-years.xlsx"
) %>%
  mutate(
    Type = "Fly Tipping"
  )

park_demog <- read_excel(
  "output/park_demographics.xlsx"
)

comb_work_data <- rbind(maint_data, ft_data) 

##############################################################
#                     Plot yearly totals                     #
##############################################################

# Combine maintenance and fly tipping data to plot together
work_totals <- comb_work_data %>%
  group_by(
    Type, YearStart, Year
  ) %>%
  summarise(
    Cost = sum(Cost)
  ) 

ggplot(work_totals, aes(x = YearStart, y = Cost/1e6, color = Type)) +
  geom_line() +
  geom_point() +
  theme_bw() +
  ylim(0, 10) +
  # Update x and y labels
  labs(
    y = "Yearly Cost (Millions)",
    x = "Financial Year"
    ) +
  # Update x tick labels
  scale_x_continuous(
    breaks = seq(2013, 2023, 2), 
    labels = paste(seq(13, 23, 2), seq(14, 24, 2), sep = "/")
    )

##############################################################
#               Plot yearly totals for each IMD              #
##############################################################

IMD_spend_change <- comb_work_data %>%
  left_join(
    park_demog,
    by = join_by("Old_Site_Ref")
  ) %>%
  group_by(
    Year, YearStart, IMD_quintile 
  ) %>% 
  summarise(
    Cost = sum(Cost),
    Total_Population = sum(Total_Population)
  ) %>%
  filter(
    !is.na(IMD_quintile)
  )%>%
  mutate(
    IMD_quintile = as.factor(IMD_quintile),
    Cost_per_person = Cost / Total_Population
  ) 

# Plot yearly absolute cost per person
ggplot(IMD_spend_change, aes(x = YearStart, y = Cost/1e6, color = IMD_quintile)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.5) +
  theme_bw() +
  ylim(0, 5) +
  # Update x and y labels
  labs(
    y = "Yearly Cost (Million £)",
    x = "Financial Year",
    color = "IMD Quintile"
  ) +
  # Update x tick labels
  scale_x_continuous(
    breaks = seq(2013, 2023, 2), 
    labels = paste(seq(13, 23, 2), seq(14, 24, 2), sep = "/")
  ) +
  # Change colour scale to be perceptually uniform (accessibility)
  viridis::scale_color_viridis(discrete = TRUE, option = "D", 
                               begin = 0, end = 0.9)
ggsave("output/figures/imd-cost-change.png", width = 5, height = 3)

# Plot yearly absolute cost per person
ggplot(IMD_spend_change, aes(x = YearStart, y = Cost_per_person, color = IMD_quintile)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.5) +
  theme_bw() +
  # Update x and y labels
  labs(
    y = "Yearly Cost (£) per person within 1km",
    x = "Financial Year",
    color = "IMD Quintile"
  ) +
  # Update x tick labels
  scale_x_continuous(
    breaks = seq(2013, 2023, 2), 
    labels = paste(seq(13, 23, 2), seq(14, 24, 2), sep = "/")
  ) +
  # Change colour scale to be perceptually uniform (accessibility)
  viridis::scale_color_viridis(discrete = TRUE, option = "D", 
                              begin = 0, end = 0.9)
ggsave("output/figures/imd-cost-change_pp.png", width = 5, height = 3)
##############################################################
#                  Plot total cost vs IMD                    #
##############################################################

# Create data frame with 2013 cost for each park
first_date <- comb_work_data %>%
  filter(
    YearStart == 2013
  ) %>% 
  group_by(Old_Site_Ref) %>%
  summarise(
    First_Cost = sum(Cost)
  )

# Create data frame with 2023 cost for each park
last_date <- comb_work_data %>%
  filter(
    YearStart == 2023
  ) %>% 
  group_by(Old_Site_Ref) %>%
  summarise(
    Last_Cost = sum(Cost)
  )

# Create data frame with total cost, cost change, and demographic data
# for each park
park_totals_and_change <- comb_work_data %>%
  group_by(
    Old_Site_Ref
  ) %>%
  summarise(
    Total_Cost = sum(Cost)
  ) %>%
  left_join(
    first_date,
    by = join_by("Old_Site_Ref")
  ) %>%
  left_join(
    last_date,
    by = join_by("Old_Site_Ref")
  ) %>%
  mutate(
    Spend_Change = Last_Cost - First_Cost
  ) %>%
  left_join(
    park_demog,
    by = join_by("Old_Site_Ref")
  ) %>%
  mutate(
    `Non-white %` = 100*(Total_Population - White)/Total_Population
  )

# Total cost (2013-2023) vs IMD rank
ggplot(park_totals_and_change, 
       aes(IMD_rank, Total_Cost)
       ) +
  geom_point() +
  theme_bw()

# Spend change (2013-2023) vs IMD rank
ggplot(park_totals_and_change, 
       aes(IMD_rank, Spend_Change)
) +
  geom_point() +
  theme_bw()

# Total cost (2013-2023) vs local Non-white population %
ggplot(park_totals_and_change, 
       aes(`Non-white %`, Total_Cost)
) +
  geom_point() +
  theme_bw()


# Spend change (2013-2023) vs local Non-white population %
ggplot(park_totals_and_change, 
       aes(`Non-white %`, Spend_Change)
) +
  geom_point() +
  theme_bw()