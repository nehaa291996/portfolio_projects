-- Inspecting Data
SELECT * FROM [dbo].[sales_data_sample];

--Checking Unique Values
SELECT DISTINCT STATUS FROM [dbo].[sales_data_sample];
SELECT DISTINCT YEAR_ID FROM [dbo].[sales_data_sample];
SELECT DISTINCT PRODUCTLINE FROM [dbo].[sales_data_sample];
SELECT DISTINCT COUNTRY FROM [dbo].[sales_data_sample];
SELECT DISTINCT DEALSIZE FROM [dbo].[sales_data_sample];
SELECT DISTINCT TERRITORY FROM [dbo].[sales_data_sample];

--Analysis
--Total Sales by Productline 
SELECT DISTINCT(PRODUCTLINE), ROUND(SUM(SALES),2) REVENUE
FROM [dbo].[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY REVENUE DESC;

--Revenue per Year
SELECT DISTINCT(YEAR_ID), ROUND(SUM(SALES),2) REVENUE
FROM [dbo].[sales_data_sample]
GROUP BY YEAR_ID
ORDER BY REVENUE DESC;

--Revenue per Deal Size
SELECT DISTINCT(DEALSIZE), ROUND(SUM(SALES),2) REVENUE
FROM [dbo].[sales_data_sample]
GROUP BY DEALSIZE
ORDER BY REVENUE DESC;

--Top Customers by Total Sales
SELECT CUSTOMERNAME, ROUND(SUM(SALES),2) AS TOTALSALES
FROM [dbo].[sales_data_sample]
GROUP BY CUSTOMERNAME
ORDER BY TOTALSALES DESC;

--Average quantity of products ordered per order
SELECT ORDERNUMBER, AVG(QUANTITYORDERED) AS AvgQtyOrdered
FROM [dbo].[sales_data_sample]
GROUP BY ORDERNUMBER
ORDER BY AvgQtyOrdered DESC;

--Largest deal by dealsize
SELECT DEALSIZE, ROUND(MAX(SALES),2) AS SALES
FROM [dbo].[sales_data_sample]
GROUP BY DEALSIZE
ORDER BY SALES DESC;

--Number of Orders that were not shipped or resolved
SELECT STATUS, COUNT(*) as TOTALCOUNT
FROM [dbo].[sales_data_sample]
WHERE STATUS IN ('On Hold', 'Cancelled', 'Disputed', 'In Process')
GROUP BY STATUS
ORDER BY TOTALCOUNT DESC;

--Analyzing the reason for significant reduction in revenue in 2005
SELECT DISTINCT(MONTH_ID)
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2005; 
/*the company operated five months in 2005 compared to other years where it was fully operational from Jan to December*/

--Best month for sale in a specific year and the revenue earned that month
SELECT MONTH_ID, ROUND(SUM(SALES),2) REVENUE, COUNT(ORDERNUMBER) FREQUENCY
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 --change year to see the desired result
GROUP BY MONTH_ID
ORDER BY REVENUE DESC;

--Ranking of Customers based on purchasing frequency
SELECT customername, COUNT(DISTINCT ordernumber) AS order_count,
       RANK() OVER (ORDER BY COUNT(DISTINCT ordernumber) DESC) AS customer_rank
FROM [dbo].[sales_data_sample]
GROUP BY customername
ORDER BY customer_rank;

--Why November has the highest revenue in 2004? Which products sell the most?
SELECT MONTH_ID, PRODUCTLINE, ROUND(SUM(SALES),2) REVENUE, COUNT(ORDERNUMBER) FREQUENCY
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 AND MONTH_ID=11--change year to see the desired result
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY REVENUE DESC;

--Who is our best customer? (Customer Segmentaion with RFM Analysis)
/*Recency, Frequency, Monetary Analysis
Recency-Last Order Purchased
Frequency-Count of total orders
Montary Value-Total Spend*/
DROP TABLE IF EXISTS #rfm
;WITH rfm AS
(
 SELECT CUSTOMERNAME,
 SUM(SALES) MonetaryValue,
 AVG(SALES) AvgMonetaryValue,
 COUNT(SALES) Frequency,
 MAX(ORDERDATE) LastOrderDate,
    (SELECT MAX(ORDERDATE) 
     FROM [dbo].[sales_data_sample]) MaxOrderDate,
 DATEDIFF(DD,MAX(ORDERDATE),(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample])) Recency
 FROM [dbo].[sales_data_sample]
 GROUP BY CUSTOMERNAME
 ),
 rfm_calc AS
  (SELECT r.*,
        NTILE(4) OVER (ORDER BY Recency desc) rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) rfm_freqency,
		NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
   FROM rfm r
 )
 SELECT
       c.*, rfm_recency+ rfm_freqency+rfm_monetary AS rfm_cell,
	   cast(rfm_recency as varchar)+ cast(rfm_freqency as varchar)+ cast(rfm_monetary as varchar) AS rfm_string_cell
 INTO #rfm
 FROM rfm_calc c;

 
 SELECT CUSTOMERNAME,rfm_recency,rfm_freqency,rfm_monetary,
  CASE
        WHEN rfm_string_cell IN (111,112,121,122,123,132,211,212,114,141) THEN 'Lost Customer'
		WHEN rfm_string_cell IN (133,134,143,244,334,343,344,144) THEN 'Slipping Away, Cannot Lose' -- Big Customers
		WHEN rfm_string_cell IN (311,411,331) THEN 'New Customer'
		WHEN rfm_string_cell IN (222,233,223,322,221) THEN 'Potential Churner'
		WHEN rfm_string_cell IN (323,333,321,422,332,432,421,232,412,232,234) THEN 'Active Customer' --Customers who buy often and recently, but spend less
		WHEN rfm_string_cell IN (433,434,443,444,423) THEN 'Loyal Customer'
  END rfm_segment
 FROM #rfm;

--Average percentage difference between the actual price and the MSRP for each product
 SELECT productcode, ROUND(AVG((priceeach - msrp) / msrp * 100),2) AS price_variance_percentage
 FROM [dbo].[sales_data_sample]
 GROUP BY PRODUCTCODE;

 --Analysis for products sold together(check where two orders are sold)
 --select * from [dbo].[sales_data_sample] where Ordernumber = 10411
 
 SELECT DISTINCT ORDERNUMBER, STUFF(
   (SELECT ','+ PRODUCTCODE 
   FROM [dbo].[sales_data_sample]P
   WHERE ORDERNUMBER IN
   (
     SELECT ORDERNUMBER
	 FROM
       (
	    SELECT ORDERNUMBER, COUNT(*) AS rn
        FROM [dbo].[sales_data_sample]
	    WHERE STATUS = 'Shipped'
        GROUP BY ORDERNUMBER
	   )m
	 WHERE rn=2
	 AND P.ORDERNUMBER = S.ORDERNUMBER
	 )
	FOR XML PATH (''))
	,1,1,'')ProductCodes
 FROM [dbo].[sales_data_sample]S
 ORDER BY 2 DESC;



 





























