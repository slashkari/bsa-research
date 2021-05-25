from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
import pandas as pd
import os
import requests
import lxml.html as lh
import re

# distance to each of 5 points in outfield, average fence distance, deepest part, avg temp of park,
# fence height, fair territory area, foul territory area, size of batter's eye, 
# orientation of home plate (facing west, east, etc.), whether indoor or outdoor stadium,
# distance to ocean, avg humidity, avg air pressure

# might need to repeat first 2 columns
# teams
team = pd.Series(['TEX', 'ARI', 'ATL', 'STL', 'KCR', 'WSN', 'MIA', 'LAA', 'PHI', 'BAL', 
'CIN', 'LAD', 'HOU', 'COL', 'NYY', 'MIL', 'PIT', 'NYM', 'TBR', 'SDP', 'MIN', 'CHW', 'DET', 
'TOR', 'CLE', 'BOS', 'CHC', 'SEA', 'OAK', 'SFG'], name = 'Team')

# avg temperature of park
# avg gametime temperatures of home parks from last 20 years (1997-2017)
temp = pd.Series([84.3, 81.1, 80.2, 78.5, 77.3, 76.9, 76.3, 75.6, 75.5, 75.3, 74.3, 
74.2, 74, 73.7, 73.7, 73.6, 73.4, 72.8, 72, 71.5, 71.3, 71, 70.2, 70, 69.9, 69.4, 68.3, 
67.2, 65.6, 64.3], name = 'Temp')

# team abbrevs that have changed throughout the years
# key is old, value is new abb
problem = {'FLA':'MIA', 'ANA':'LAA', 'MON':'WSN', 'TBD':'TBR'}

# scrape offensive stats for every team
output = pd.DataFrame()
years = list(range(1997, 2021))
driver = webdriver.Chrome()

# start off at 1997 team offensive stats page
# only need dashboard, not advanced
driver.get("https://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type=8&season=1997&month=0&season1=1997&ind=0&team=0,ts&rost=0&age=0&filter=&players=0&startdate=1997-01-01&enddate=1997-12-31")

for year in years:
    yearDropDown = driver.find_element_by_id("LeaderBoard1_rcbSeason_Arrow")
    driver.execute_script("arguments[0].click();", yearDropDown) # click year drop down button
    time = driver.find_element_by_xpath('//*[text()=' + str(year) + ']')
    driver.execute_script("arguments[0].click();", time) # click desired year

    # from https://towardsdatascience.com/web-scraping-html-tables-with-python-c9baba21059
    # using requests, lxml.html libs
    url = driver.current_url
    page = requests.get(url)
    doc = lh.fromstring(page.content)

    # entire table stored as rows (len = 28)
    tr_elements = doc.xpath("//tr[@class='rgRow' or @class='rgAltRow']")

    if year == 1997:
        # get column names only once
        colnames = doc.xpath("//tr/th[@class='rgHeader' or @class='grid_line_breakh rgHeader']")
        colnames = [str(colnames[i].text_content()) for i in range(len(colnames))]
        colnames = [re.sub("%", "rate", x) for x in colnames]
        colnames = [re.sub("#", "num", x) for x in colnames]
        colnames = [re.sub("\+", "plus", x) for x in colnames]
        

    tempOutputDict = {}

    # iterate through columns then rows
    for i in range(0, len(colnames)):
        for j in range(0, len(tr_elements)):
            if j == 0:
                tempOutputDict[colnames[i]] = [] # add new column
            data = tr_elements[j][i].text_content()
            if data in problem.keys():
                data = problem[data]
            tempOutputDict[colnames[i]].append(data)
        
    tempOutput = pd.DataFrame(tempOutputDict) # convert to df
    yearCol = pd.Series([year] * len(tr_elements), name = 'Year') # create series of years
    tempOutput = pd.concat([tempOutput, yearCol], axis = 1) # add years column
    
    # convert all elements to str then numeric (if possible)
    tempOutput = tempOutput.astype(str)
    tempOutput = tempOutput.apply(pd.to_numeric, errors = "ignore")

    if year == 1997:
        output = tempOutput
    else:
        output = pd.concat([output, tempOutput], ignore_index = True)

driver.close()
# output.shape # 718x23 (30*23 + 28) = 718

# delete some columns
output.drop('num', inplace = True, axis = 1)
output.drop('BsR', inplace = True, axis = 1)
output.drop('Off', inplace = True, axis = 1)
output.drop('Def', inplace = True, axis = 1)

# make df of temps with corresponding team
tempdf = pd.concat([team, temp], axis = 1)

# join this with output df
output = output.merge(tempdf, on = 'Team', how = 'left')


# 0 for open, 1 for enclosed, 2 for retractable, 3 for partially enclosed
# comment years of operation for each stadiums with roofs (shouldn't be many)
# HOU - 2000-present (retractable), before enclosed
# MIA - partially enclosed (until 2011), retractable (2012-present)
# TEX - open (until 2019), retractable (2020-present)
# MIL - open (until 2000), retractable (2001-present)
# MIN - closed (until 2009), open (2010-present)
# TOR - retractable (1989-2019), open (2020-present), Dunedin
# ARI - retractable
# TBR - closed
# WSN/MON - retractable until 2004, open (2005-present)
# SEA - closed until 1998, retractable (1999-present)

roof_97 = pd.Series([1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 2])
roof_98 = pd.Series([0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 2, 0, 0, 0, 0, 0, 1])
roof_99 = pd.Series([0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 0])
roof_00 = pd.Series([0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1])
roof_01 = pd.Series([2, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 1, 2])
roof_02 = pd.Series([0, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 0, 0, 1, 0, 2, 0, 0, 0])
roof_03 = pd.Series([0, 0, 0, 2, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0])
roof_04 = pd.Series([0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 0, 0, 2, 0, 2, 0, 2, 0, 2])
roof_05 = pd.Series([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 2, 2, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 1, 0, 2, 0, 0])
roof_06 = pd.Series([0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 1, 0])
roof_07 = pd.Series([0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 2, 0, 0, 0, 1, 0, 0, 2, 0, 2, 0])
roof_08 = pd.Series([0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 2, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 0])
roof_09 = pd.Series([1, 0, 0, 0, 0, 2, 0, 0, 1, 0, 0, 2, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0])
roof_10 = pd.Series([0, 0, 1, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0])
roof_11 = pd.Series([0, 0, 0, 2, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2])
roof_12 = pd.Series([0, 0, 0, 0, 2, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 2, 0, 2])
roof_13 = pd.Series([0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 2, 0, 0, 2, 2])
roof_14 = pd.Series([0, 0, 0, 0, 0, 0, 0, 2, 0, 2, 1, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0])
roof_15 = pd.Series([2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 0, 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0])
roof_16 = pd.Series([0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 2, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0])
roof_17 = pd.Series([2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 2, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0])
roof_18 = pd.Series([0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 1, 0, 2, 2, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0])
roof_19 = pd.Series([2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 2, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0])
roof_20 = pd.Series([0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 2, 0, 2, 2, 0, 0, 0, 2])

# combine all data into single list
roofs = [roof_97, roof_98, roof_99, roof_00, roof_01, roof_02, roof_03, roof_04, roof_05,
roof_06, roof_07, roof_08, roof_09, roof_10, roof_11, roof_12, roof_13, roof_14, roof_15,
roof_16, roof_17, roof_18, roof_19, roof_20]

# concatenate into one series
roof_status = pd.concat(roofs, ignore_index = True)
roof_status.name = "roof_status"

# add to output df 
output = pd.concat([output, roof_status], axis = 1)

# drop xwOBA (empty col)
output.drop('xwOBA', inplace = True, axis = 1)

# add wind variable
wind = pd.Series([9.3, 8.1, 7.9, 7.1, 8.5, 8.9, 11, 6.3, 9.6, 4.2, 7.6, 6, 7.8, 6.5, 9.4,
10.1, 8, 12, 0, 8.5, 0, 11.1, 9.7, 9.6, 10.3, 10.9, 10.2, 2.5, 11.1, 11.8], name = 'Wind')

# add team col to join with output df
wind_df = pd.concat([team, wind], axis = 1)

output = output.merge(wind_df, on = 'Team', how = 'left')


testdf = output.copy()

output.loc[(output['Year'] == 2006) & (output['Team'] == 'WSN'), 'Wind']

# change wind values for WSN from 2005 and after
for year in range(2005, 2021):
    output.loc[(output['Year'] == year) & (output['Team'] == 'WSN'), 'Wind'] = 5.8

# change wind for HOU (0 until 1999 because indoors)
for year in range(1997, 2000):
    output.loc[(output['Year'] == year) & (output['Team'] == 'HOU'), 'Wind'] = 0

# change wind for SEA (0 until 1998)
for year in range(1997, 1999):
    output.loc[(output['Year'] == year) & (output['Team'] == 'SEA'), 'Wind'] = 0

# change wind for MIN (10.5 from 2010-present)
for year in range(2010, 2021):
    output.loc[(output['Year'] == year) & (output['Team'] == 'MIN'), 'Wind'] = 10.5

# change blue jays wind for 2020 (Dunedin)
output.loc[(output['Year'] == 2020) & (output['Team'] == 'TOR'), 'Wind'] = 12.5





# miles from nearest coast
ocean = pd.Series([247, 372, 267, 689, 648, 85, 1, 20, 57, 59, 474, 16, 47, 947, 20, 732, 
305, 14, 7, 2, 1016, 680, 454, 339, 373, 5, 684, 1, 1, 1], name = 'Ocean')

ocean_df = pd.concat([team, ocean], axis = 1)

output = output.merge(ocean_df, on = 'Team', how = 'left')

# add expos distance from ocean (1997-2004)
for year in range(1997, 2005):
    output.loc[(output['Year'] == year) & (output['Team'] == 'WSN'), 'Ocean'] = 262

# change blue jays distance for 2020
output.loc[(output['Year'] == 2020) & (output['Team'] == 'TOR'), 'Ocean'] = 1





# home plate orientation (west, east, north, south)
direction = pd.Series(['east northeast', 'north', 'east northeast', 'east northeast',
'northeast', 'north northeast', 'southeast', 'northeast', 'north northeast', 'northeast',
'east southeast', 'north northeast', 'north northwest', 'north', 'east northeast', 
'southeast', 'east southeast', 'north northeast', 'northeast', 'north', 'east', 'southeast',
'south southeast', 'north', 'north', 'northeast', 'north northeast', 'northeast', 
'east northeast', 'east'], name = 'Direction')

# combine team and direction columns to join
direct_df = pd.concat([team, direction], axis = 1)

# join with output df on team
output = output.merge(direct_df, on = 'Team', how = 'left')

# change TEX, ATL, SFG, MIA, MIL, HOU, TOR, WSN directions
# change rangers direction to east southeast (1997 - 2019)
for year in range(1997, 2020):
    output.loc[(output['Year'] == year) & (output['Team'] == 'TEX'), 'Direction'] = 'east southeast'

# change braves direction to north northeast (1997-2016)
for year in range(1997, 2017):
    output.loc[(output['Year'] == year) & (output['Team'] == 'ATL'), 'Direction'] = 'north northeast'

# change giants direction to north northeast (1997-1999)
for year in range(1997, 2000):
    output.loc[(output['Year'] == year) & (output['Team'] == 'SFG'), 'Direction'] = 'north northeast'

# change marlins direction to east (1997 - 2011)
for year in range(1997, 2012):
    output.loc[(output['Year'] == year) & (output['Team'] == 'MIA'), 'Direction'] = 'east'

# change brewers direction to southeast (1997 - 2000)
for year in range(1997, 2001):
    output.loc[(output['Year'] == year) & (output['Team'] == 'MIL'), 'Direction'] = 'southeast'

# change astros direction to east (1997 - 1999)
for years in range(1997, 2000):
    output.loc[(output['Year'] == year) & (output['Team'] == 'HOU'), 'Direction'] = 'east'

# change blue jays direction to southeast (2020)
output.loc[(output['Year'] == 2020) & (output['Team'] == 'TOR'), 'Direction'] = 'southeast'

# change nationals direction to north (1997 - 2004)
for year in range(1997, 2005):
    output.loc[(output['Year'] == year) & (output['Team'] == 'WSN'), 'Direction'] = 'north'

# change phillies direction to east northeast (1997 - 2003)
for year in range(1997, 2004):
    output.loc[(output['Year'] == year) & (output['Team'] == 'PHI'), 'Direction'] = 'east northeast'

# change reds direction to east (1997 - 2002)
for year in range(1997, 2003):
    output.loc[(output['Year'] == year) & (output['Team'] == 'CIN'), 'Direction'] = 'east'

# change yankees direction to east (1997 - 2008)
for year in range(1997, 2009):
    output.loc[(output['Year'] == year) & (output['Team'] == 'NYY'), 'Direction'] = 'east'

# change pirates direction to southeast (1997 - 2000)
for year in range(1997, 2001):
    output.loc[(output['Year'] == year) & (output['Team'] == 'PIT'), 'Direction'] = 'southeast'

# change mets direction to east northeast (1997 - 2008)
for year in range(1997, 2009):
    output.loc[(output['Year'] == year) & (output['Team'] == 'NYM'), 'Direction'] = 'east northeast'

# change tigers direction to north northeast (1997-1999)
for year in range(1997, 2000):
    output.loc[(output['Year'] == year) & (output['Team'] == 'DET'), 'Direction'] = 'north northeast'



# distance to deepest part of park

# DIM CHANGES - SEA, SDP, NYM, KCR, MIA, DET, LAA
# included values that have been there the longest
# for TEX using ranger ballpark distances (will change a few lines down for correct years)
# for ATL using turner field
# for WSN using nationals park
# for MIA using hard rock stadium
# for PHI using citizens bank park
# for HOU using minute maid park
# for NYY using new yankees stadium
# for MIL using miller park 
# for PIT using PNC park
# for NYM using shea stadium
# for SDP using petco 
# for MIN using metrodome
# for SEA using safeco

deepest = pd.Series([407, 413, 401, 400, 400, 402, 420, 400, 409, 410, 404, 395, 436, 424,
408, 400, 410, 410, 412, 401, 408, 400, 420, 400, 410, 420, 400, 405, 400, 415], name = 'Deepest')

# combine deepest and team series into deepest_df
deepest_df = pd.concat([team, deepest], axis = 1)

# join deepest_df with output
output = output.merge(deepest_df, on = 'Team', how = 'left')

# now add modifications
# change TEX for 2020 only
output.loc[(output['Year'] == 2020) & (output['Team'] == 'TEX'), 'Deepest'] = 410

# change ATL to 402 (2017-present)
for year in range(2017, 2021):
    output.loc[(output['Year'] == year) & (output['Team'] == 'ATL'), 'Deepest'] = 402

# change WSN to 404 (1997-2004)
for year in range(1997, 2005):
    output.loc[(output['Year'] == year) & (output['Team'] == 'WSN'), 'Deepest'] = 404

# change MIA to 422 (2012-2015), 411 (2016-2019), 400 (2020)
for year in range(2012, 2016):
    output.loc[(output['Year'] == year) & (output['Team'] == 'MIA'), 'Deepest'] = 422

for year in range(2016, 2020):
    output.loc[(output['Year'] == year) & (output['Team'] == 'MIA'), 'Deepest'] = 411

output.loc[(output['Year'] == year) & (output['Team'] == 'MIA'), 'Deepest'] = 400

# change PHI to 408 (1997 - 2003)
for year in range(1997, 2004):
    output.loc[(output['Year'] == year) & (output['Team'] == 'PHI'), 'Deepest'] = 408

# change HOU to 406 (1997 - 1999), 409 (2017-present)
for year in range(1997, 2000):
    output.loc[(output['Year'] == year) & (output['Team'] == 'HOU'), 'Deepest'] = 406

for year in range(2017, 2021):
    output.loc[(output['Year'] == year) & (output['Team'] == 'HOU'), 'Deepest'] = 409

# change NYY to 408 (1997-2008)
for year in range(1997, 2009):
    output.loc[(output['Year'] == year) & (output['Team'] == 'NYY'), 'Deepest'] = 408

# change MIL to 402 (1997-2000)
for year in range(1997, 2001):
    output.loc[(output['Year'] == year) & (output['Team'] == 'MIL'), 'Deepest'] = 402

# change PIT to 400 (1997-2000)
for year in range(1997, 2001):
    output.loc[(output['Year'] == year) & (output['Team'] == 'PIT'), 'Deepest'] = 400

# change NYM to 415 (2009-2011), 408 (2012-present)
for year in range(2009, 2012):
    output.loc[(output['Year'] == year) & (output['Team'] == 'NYM'), 'Deepest'] = 415

for year in range(2013, 2021):
    output.loc[(output['Year'] == year) & (output['Team'] == 'NYM'), 'Deepest'] = 408

# change SDP to 411 (1997-2003), 411 (2004), 401 (2005-2012), 396 (2013-present)
for year in range(1997, 2004):
    output.loc[(output['Year'] == year) & (output['Team'] == 'SDP'), 'Deepest'] = 411

output.loc[(output['Year'] == 2004) & (output['Team'] == 'SDP'), 'Deepest'] = 411

for year in range(2013, 2021):
    output.loc[(output['Year'] == year) & (output['Team'] == 'SDP'), 'Deepest'] = 396

# change MIN to 411 (2010-present)
for year in range(2010, 2021):
    output.loc[(output['Year'] == year) & (output['Team'] == 'MIN'), 'Deepest'] = 411

# change SEA to 401 (2013-present)
for year in range(2013, 2021):
    output.loc[(output['Year'] == year) & (output['Team'] == 'SEA'), 'Deepest'] = 401

# change DET to 440 (1997-1999)
for year in range(1997, 2000):
    output.loc[(output['Year'] == year) & (output['Team'] == 'DET'), 'Deepest'] = 440




# turf or real grass
team = pd.Series(['TEX', 'ARI', 'ATL', 'STL', 'KCR', 'WSN', 'MIA', 'LAA', 'PHI', 'BAL', 
'CIN', 'LAD', 'HOU', 'COL', 'NYY', 'MIL', 'PIT', 'NYM', 'TBR', 'SDP', 'MIN', 'CHW', 'DET', 
'TOR', 'CLE', 'BOS', 'CHC', 'SEA', 'OAK', 'SFG'], name = 'Team')

# 0 for real grass, 1 for turf
# rangers ballpark 0, globe life field (2020) 1
# inclusive dates
# ARI 0 until 2018
# MIA 0 until 2019
# PHI 1 until 2003
# CIN 1 until 2002
# HOU 1 until 1999
# PIT 1 until 2000
# MIN 1 until 2009
# WSN 1 until 2004
# SEA 1 until 1998

turf_status = pd.Series([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 
0, 1, 0, 0, 0, 0, 0, 0], name = 'turf_status')

# combine teams and turf_status series to make turf_df
turf_df = pd.concat([team, turf_status], axis = 1)

# left join turf_df with output
output = output.merge(turf_df, on = 'Team', how = 'left')

# now make changes
# ARI added turf in 2019
for year in range(2019, 2021):
    output.loc[(output['Year'] == year) & (output['Team'] == 'ARI'), 'turf_status'] = 1

# MIA added turf in 2020
output.loc[(output['Year'] == 2020) & (output['Team'] == 'MIA'), 'turf_status'] = 1

# PHI turf until 2003 (including 2003)
for year in range(1997, 2004):
    output.loc[(output['Year'] == year) & (output['Team'] == 'PHI'), 'turf_status'] = 1

# CIN turf until 2002
for year in range(1997, 2003):
    output.loc[(output['Year'] == year) & (output['Team'] == 'CIN'), 'turf_status'] = 1

# HOU turf until 1999
for year in range(1997, 2000):
    output.loc[(output['Year'] == year) & (output['Team'] == 'HOU'), 'turf_status'] = 1

# PIT turf until 2000
for year in range(1997, 2001):
    output.loc[(output['Year'] == year) & (output['Team'] == 'PIT'), 'turf_status'] = 1

# MIN turf until 2009
for year in range(1997, 2010):
    output.loc[(output['Year'] == year) & (output['Team'] == 'MIN'), 'turf_status'] = 1

# WSN turf until 2004
for year in range(1997, 2005):
    output.loc[(output['Year'] == year) & (output['Team'] == 'WSN'), 'turf_status'] = 1

# SEA turf until 1998
for year in range(1997, 1999):
    output.loc[(output['Year'] == year) & (output['Team'] == 'SEA'), 'turf_status'] = 1



# fence height 


# elevation, avg humidity, avg temp in summer



# save
# path = r'C:/Users/slash/Documents/bsa-research/data'
# output_file = os.path.join(path, "park_factors.csv")
# output.to_csv(output_file, index = False)
