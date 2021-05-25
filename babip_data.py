from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
import pandas as pd
import os

teams = {'HOU':list(range(2005, 2021)),
         'MIA':list(range(2006, 2021)),
         'SDP':list(range(2003, 2021)),
         'SEA':list(range(2003, 2021)),
         'ATL':list(range(2004, 2021)),
         'MIN':list(range(2002, 2021))}

years = list(range(2002, 2021))

# initialize output df
output = pd.DataFrame()

# start webscraping session
driver = webdriver.Chrome()

# start off at team batting stats 2002 page
driver.get("https://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=1&season=2002&month=15&season1=2002&ind=0&team=0,ts&rost=0&age=0&filter=&players=0")

# locate dropdown menu and click on it
dropDown = driver.find_element_by_id("LeaderBoard1_rcbMonth_Arrow") # THIS WORKS
driver.execute_script("arguments[0].click();", dropDown)

# select "Home"
home = driver.find_element_by_xpath("//div[@id='LeaderBoard1_rcbMonth_DropDown']//li[27]")
driver.execute_script("arguments[0].click();", home)

# click advanced
advanced = driver.find_element_by_link_text("Advanced")
driver.execute_script("arguments[0].click();", advanced)

for year in years:

    # click year drop down menu
    yearDropDown = driver.find_element_by_id("LeaderBoard1_rcbSeason_Arrow")
    driver.execute_script("arguments[0].click();", yearDropDown)

    # click appropriate year
    time = driver.find_element_by_xpath('//*[text()=' + str(year) + ']')
    driver.execute_script("arguments[0].click();", time)
    
    # get data from table
    table = driver.find_elements_by_class_name("grid_line_regular")

    tempTeam = []
    tempBabip = []

    # fill out list of teams
    for i in range(1, len(table), 17):
        tempTeam.append(table[i].text)

    # change FLA to MIA if it appears in tempTeam
    try:
        miaIndex = tempTeam.index('FLA')
        tempTeam[miaIndex] = 'MIA'
    except ValueError:
        pass
    
    # fill out list of BABIP values
    for i in range(12, len(table), 17):
        tempBabip.append(table[i].text)

    # list of babips of all teams for given year before subsetting
    yearList = [int(year)] * 30
    df = pd.DataFrame({'Team':tempTeam, 'BABIP':tempBabip, 'Year':yearList})

    # keep only teams with corresponding year in teams dict
    # loop finds which teams to keep
    keep = []

    for key in teams.keys():
        if year in teams[key]:
            keep.append(key)
        
    # filter df to just kept teams
    df = df.loc[df['Team'].isin(keep)] # need regex stuff here

    output = output.append(df) # append doesn't happen in place, need to store it

driver.close()

# need to sort df by team and year, get rid of row numbers and write to csv
# provide this ordering HOU, MIA, SDP, SEA, ATL, MIN
output["Team"] = pd.Categorical(output["Team"], ["HOU", "MIA", "SDP", "SEA", "ATL", "MIN"])
output = output.sort_values(["Team", "Year"])

# write to csv
path = r'C:/Users/slash/Documents/bsa-research/data'
output_file = os.path.join(path, "wrcplus_data.csv")
output.to_csv(output_file, index = False)







