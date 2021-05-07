import pandas as pd
from nltk.stem.porter import *
from ethnicolr import census_ln, pred_census_ln

data = pd.read_csv("./Disney.csv")

def get_words(text):
    letters_only = re.sub("[^a-zA-Z_]"," ", text)
    words = letters_only.lower()
    return(words)

ntweet = len(data.index)
name2 = [0]*ntweet
for i in data.index:
    name2[i] = get_words(data['user_name'][i])
location2 = [0]*ntweet
for i in data.index:
    location2[i] = get_words(str(data['user_location'][i]))

data['user_name2'] = name2
data['user_location2'] = location2
data.to_csv("./Disney2.csv",index=False)

# from Disney2.csv to Disney_name.csv:
# Split the user_name2 column into two columns;
# Manually select rows for which the two columns contain forename and surname, respectively.

data_name = pd.read_csv("./Disney_name.csv")
data2 = census_ln(data, 'last_name', 2010)
data3 = pred_census_ln(data, 'last_name')
data3.to_csv("./Disney_race.csv", index=False)


# from Disney2.csv to Disney_location.csv:
# Split the user_location2 column into two columns;
# Manually select rows for which the second column contains state names.

