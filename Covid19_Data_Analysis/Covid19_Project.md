##Objective

The aim of this project is to provide an overview of COVID-19 mortality rates across various countries and to illustrate how the pandemic has evolved over time through its different waves.

##Skills Demonstrated

This project showcases my expertise in data preparation and cleaning using SQL, as well as data visualization using Tableau.

##Key Questions Answered

How many people have died due to COVID-19?
What is the percentage of deaths relative to the population in each country?
How is the number of deaths correlated with the Stringency Index? 

*The stringency index is a composite measurebased on nine response indicators including schoolclosures, workplace closures, and travel bans,rescaled to a value from 0 to 100 (100 = strictest)

 
##Steps to Conduct the Project

1. Data Collection
Source: Downloaded dataset from [Our world in data](https://ourworldindata.org/covid-deaths)
Data Preparation: Created two Excel files (CovidDeaths.xlsx and CovidVaccinations.xlsx)
Data Upload: Uploaded both files to Microsoft SQL Server

2. Data Cleaning and Preparation in SQL
Conducted data cleaning to rectify incorrect data types and handle missing values
Conducted exploratory data analysis to understand the dataset's structure and variables
Created two SQL views named v_CovidDeaths and v_CovidVaccinations
For the purpose of data visualization, created an additional SQL view named v_CovidDeathsVaccinations_weekly
SQL scripts are available [here](/Covid19_Data_Analysis/DataExploration.sql)

3. Data Visualization in Tableau
Prepared two datasets for uploading to Tableau: CovidDeathsVaccination_weekly.csv and WorldDeathsTotal.csv
Uploaded the datasets to Tableau
Created and published the dashboard, which is accessible [here](https://public.tableau.com/views/Covid-19Deaths_16951637623330/Dashboard1?:language=en-US&publish=yes&:display_count=n&:origin=viz_share_link)
![image](https://github.com/jbaidalina/PortfolioProjects/assets/25383004/fe816443-28a0-46e8-8490-6ad8367fca38)




