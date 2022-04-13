# Overview

The purpose of this analysis was to utilize a dataset of Amazon product reviews and, leveraging PySpark, Amazon AWS and pgAdmin, build an ETL pipeline and analyze the dataset. 

The analysis itself centers around bias, and whether Amazon Vine members show bias towards favorable reviews.

The dataset chosen for this project was the Musical Instrument dataset, found here: [Amazon_Reviews_US_Musical_Instruments](https://s3.amazonaws.com/amazon-reviews-pds/tsv/amazon_reviews_us_Musical_Instruments_v1_00.tsv.gz)

# Results

## ETL

Using PySpark, the following steps were executed:

1. The Amazon data was loaded into a Spark dataframe
```python
from pyspark import SparkFiles
url = "https://s3.amazonaws.com/amazon-reviews-pds/tsv/amazon_reviews_us_Musical_Instruments_v1_00.tsv.gz"
spark.sparkContext.addFile(url)
df = spark.read.option("encoding", "UTF-8").csv(SparkFiles.get(""), sep="\t", header=True, inferSchema=True)
df.show()
```
2. From this dataframe, four other dataframes were created:
   - A customer dataframe was created
    ```python
    customers_df = df.groupby("customer_id").agg({"customer_id":"count"}).withColumnRenamed("count(customer_id)", "customer_count")
    ```
    - A product dataframe was created
    ```python
    products_df = df.select(["product_id","product_title"]).drop_duplicates()
    ```
   - A review table was created
    ```python
    review_id_df = df.select(["review_id","customer_id","product_id","product_parent",to_date("review_date", 'yyyy-MM-dd').alias("review_date")])
    ```
    - A Vine table was created
    ```python
    vine_df = df.select(["review_id","star_rating","helpful_votes","total_votes","vine","verified_purchase"])
    ```
3. From here, the AWS RDS instance was connected to, and the dataframes were written to tables

```python
# Configure settings for RDS
mode = "append"
jdbc_url="jdbc:postgresql://amazonvineanalysis-lalib.cjhgppelqq1d.us-east-1.rds.amazonaws.com:5432/postgres"
config = {"user":"[REDACTED]", 
          "password": "[REDACTED]", 
          "driver":"org.postgresql.Driver"}
# Write review_id_df to table in RDS
review_id_df.write.jdbc(url=jdbc_url, table='review_id_table', mode=mode, properties=config)
# Write products_df to table in RDS
products_df.write.jdbc(url=jdbc_url, table='products_table', mode=mode, properties=config)
# Write customers_df to table in RDS
customers_df.write.jdbc(url=jdbc_url, table='customers_table', mode=mode, properties=config)
# Write vine_df to table in RDS
vine_df.write.jdbc(url=jdbc_url, table='vine_table', mode=mode, properties=config)
```

Using pgAdmin, the following queries verified that the process was a success:

![](resources/Screen%20Shot%202022-04-10%20at%2011.19.06%20PM.png)
![](resources/Screen%20Shot%202022-04-10%20at%2011.19.34%20PM.png)
![](resources/Screen%20Shot%202022-04-10%20at%2011.19.58%20PM.png)
![](resources/Screen%20Shot%202022-04-10%20at%2011.20.30%20PM.png)

## The Analysis

SQL was chosen to complete the following analysis. 

1. The vine table was filtered to reviews that contained 20 or more votes
    ```sql
    SELECT * 
    INTO twenty_plus_votes
    FROM vine_table
    WHERE total_votes >= 20
    ```
2. The remaining reviews were filtered so as the percentage of `helpful_votes` is equal to or greater than 50%.
    ```sql
    SELECT *
	INTO helpful_vine
    FROM twenty_plus_votes
    WHERE CAST(helpful_votes AS FLOAT)/CAST(total_votes AS FLOAT) >=0.5
    ```
3. A table was created featuring helpful votes filtered to `vine='Y'` (vine users)
    ```sql
    SELECT *
    INTO vine_Yes
    FROM helpful_vine
    WHERE vine = 'Y'
    ```
4. A table was created featuring helpful votes filtered to `vine='N'` (non-vine users)
    ```sql
    SELECT *
    INTO vine_No
    FROM helpful_vine
    WHERE vine = 'N'
    ```

### Preview 
The following query was run to preview the totals:
```sql
SELECT (SELECT COUNT(review_id) FROM twenty_plus_votes) as Filtered_to_TwentyPlus, 
(SELECT COUNT(review_id) FROM helpful_vine) as Filtered_to_Helpful,
(SELECT COUNT(review_id) FROM vine_Yes) as vine_Yes,
(SELECT COUNT(review_id) FROM vine_No) as vine_No
```
![](resources/Screen%20Shot%202022-04-12%20at%206.47.42%20PM.png)

**Analyst Comment**: Already we can see an issue with the data, as the total count of vine users is significantly smaller than non-vine users (60 vine to 14,477 non-vine). Even if there is a bias in star reviews between vine and non-vine, non-vine users are overrepresented in the total vote count.

### Final Query

```sql
SELECT (SELECT COUNT(review_id) FROM helpful_vine) as "Total Votes(w/ 20+ votes, 50%+ Helpful Rating)",
(SELECT COUNT(review_id) FROM helpful_vine where star_rating = 5) as "Total 5 Star Ratings",
CAST((SELECT COUNT(review_id) FROM helpful_vine where star_rating = 5) AS FLOAT) / CAST((SELECT COUNT(review_id) FROM helpful_vine) AS FLOAT) * 100 as "% of 5 Star Reviews",
(SELECT COUNT(review_id) FROM vine_Yes) as "Total Vine=Y Votes",
(SELECT COUNT(review_id) FROM vine_Yes where star_rating = 5) as "Total 5 Star Vine=Y Votes",
CAST((SELECT COUNT(review_id) FROM vine_Yes where star_rating = 5) AS FLOAT) / CAST((SELECT COUNT(review_id) FROM vine_Yes) AS FLOAT) * 100 as "% of Vine=Y 5 Star Reviews",
(SELECT COUNT(review_id) FROM vine_No) as "Total Vine=N Votes",
(SELECT COUNT(review_id) FROM vine_No where star_rating = 5) as "Total 5 Star Vine=N Votes",
CAST((SELECT COUNT(review_id) FROM vine_No where star_rating = 5) AS FLOAT) / CAST((SELECT COUNT(review_id) FROM vine_No) AS FLOAT) * 100 as "% of Vine=N 5 Star Reviews"
```
![](resources/Screen%20Shot%202022-04-12%20at%208.23.20%20PM.png)

### Key Questions - Answered

1. How many Vine reviews and non-Vine reviews were there?
   - **Vine Reviews**: 60
   - **Non-Vine Reviews**: 14,447
2. How many Vine reviews were 5 stars? How many non-Vine reviews were 5 stars?
   - **5 Star Vine Reviews**: 34
   - **5 Star Non-Vine Reviews**: 8,212
3. What percentage of Vine reviews were 5 stars? What percentage of non-Vine reviews were 5 stars?
   - **5 Star Vine Reviews**: 56.67%
   - **5 Star Non-Vine Reviews**: 56.72%

# Summary

Two observations can be made based on the analysis:
1. There is no evidence of bias between Vine and non-Vine reviews, as the percentages were nearly identical.
2. Given that the total Vine review count is so low, any bias resulting from Vine reviews would have little impact on the end result.

An additional query, which was included in the final query section above but worth highlighting alone, is the percentage of total 5 star reviews compared to the total amount of reviews. This query would show how the vina/non-vine ratios compare to the overall ratio.

```sql
SELECT CAST((SELECT COUNT(review_id) FROM helpful_vine where star_rating = 5) AS FLOAT) / CAST((SELECT COUNT(review_id) FROM helpful_vine) AS FLOAT) * 100 as "% of 5 Star Reviews",
CAST((SELECT COUNT(review_id) FROM vine_Yes where star_rating = 5) AS FLOAT) / CAST((SELECT COUNT(review_id) FROM vine_Yes) AS FLOAT) * 100 as "% of Vine=Y 5 Star Reviews",
CAST((SELECT COUNT(review_id) FROM vine_No where star_rating = 5) AS FLOAT) / CAST((SELECT COUNT(review_id) FROM vine_No) AS FLOAT) * 100 as "% of Vine=N 5 Star Reviews"
```
![](resources/Screen%20Shot%202022-04-12%20at%2010.12.04%20PM.png)