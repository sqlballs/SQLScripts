#============================================================
# Source via Bradley Ball :: braball@micrsoft.com
# MIT License
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
# THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
#==============================================================


import pyodbc
import pandas as pd
import openai
import os
from langchain.llms import AzureOpenAI
import warnings
warnings.filterwarnings('ignore')

server = '' 
database = '' 
username = '' 
password = '' 

cnxn = pyodbc.connect('Driver={ODBC Driver 18 for SQL Server};Server=tcp:' + server +';Database='+database+';Uid='+username+';Pwd='+password+';Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;')
cursor = cnxn.cursor()
# select 10 rows from SQL table to insert in dataframe.
query = "select * from [dbo].[table];"
df = pd.read_sql(query, cnxn)
#print(df.head(10))

os.environ["OPENAI_API_TYPE"] = "azure"
os.environ["OPENAI_API_KEY"] = "c300c488dd4e47dfbcb8ad1baba40ac0"
os.environ["OPENAI_API_BASE"] = "https://bballazureopenai.openai.azure.com/"
os.environ["OPENAI_API_VERSION"] = "2022-12-01"

llm = AzureOpenAI(deployment_name="", model_name="",model_kwargs={"api_type": "azure", "api_version": "2022-12-01"}) 


from langchain.agents import create_pandas_dataframe_agent
agent = create_pandas_dataframe_agent(llm, df, verbose=True)

agent.run("Ask a question?")
