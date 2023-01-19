use rfm;

-- inspecting th data
select * from sales_data_sample;

-- checking for null values
select * from sales_data_sample 
where coalesce(ordernumber, quantityordered, priceeach,
				sales, orderdate, status, qtr_id, month_id,
                year_id, productline, msrp, productcode,
                customername, city, state, postalcode, 
                country, territory, contactfirstname, 
                contactlastname, dealsize
                )
is null;

-- checking distinct values
select distinct status from sales_data_sample;
select distinct qtr_id from sales_data_sample;
select distinct MONTH_ID from sales_data_sample;
select distinct YEAR_ID from sales_data_sample;
select distinct COUNTRY from sales_data_sample;
select distinct DEALSIZE from sales_data_sample;
select distinct TERRITORY from sales_data_sample;
select distinct PRODUCTLINE from sales_data_sample;

-- ANALYSIS 
-- grouping sales by productline
select PRODUCTLINE, sum(sales) Revenue
from sales_data_sample
group by PRODUCTLINE
order by Revenue desc;


select YEAR_ID, sum(sales) Revenue
from sales_data_sample
group by YEAR_ID
order by Revenue desc;

select  DEALSIZE,  sum(sales) Revenue
from sales_data_sample
group by  DEALSIZE
order by Revenue desc;


-- What was the best month for sales in a specific year? How much was earned that month? 
select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from sales_data_sample
where YEAR_ID = 2004 
group by  MONTH_ID
order by Revenue desc;


-- November seems to be the month, what product was sold most
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER)
from sales_data_sample
where YEAR_ID = 2004 and MONTH_ID = 11 -- for all years november seems to the big earner
group by  MONTH_ID, PRODUCTLINE
order by Revenue desc;


-- What city has the highest number of sales in a specific country

select city, sum(sales) as Revenue
from sales_data_sample
where country = 'UK'
group by city
order by 2 desc;


-- What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from sales_data_sample
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc;


-- Changing column ( order_date ) type text to date

update sales_data_sample
set orderdate = str_to_date(orderdate,"%m/%d/%Y %T");

-- This was done as our data was present in above format above and mysql dosen't 
-- recognize that format or rather recognizes only %Y-%m-%d format so I had to convert it before changing to date type.

alter table sales_data_sample
modify orderdate date;


-- Who is our best customer (this could be best answered with RFM)
-- Using cte for rfm segmentation

with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		timestampdiff(DAY,max(ORDERDATE), (select max(ORDERDATE) from sales_data_sample)) Recency
	from sales_data_sample
	group by CUSTOMERNAME
),
rfm_calc as
(

	select
        NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm 
),
rfm_segmentation as
(

select
    rfm_recency, rfm_frequency, rfm_monetary,
    concat(rfm_recency, rfm_frequency, rfm_monetary) as rfm_cell    
from rfm_calc
)
select 
	rfm_recency, rfm_frequency, rfm_monetary,rfm_cell,
	case 
		when rfm_cell in (111, 112 , 121, 122, 123, 132, 211, 221, 212, 114, 141) then 'lost customers'  -- lost customers
		when rfm_cell in (113,133, 134, 143, 232, 234, 244, 334, 343, 344, 144) then 'at risk' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell in (311, 411, 412, 331) then 'new customers'
		when rfm_cell in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell in (131,323, 333,321,421, 422, 332, 432, 423) then 'active' -- (Customers who buy often & recently, but at low price points)
		when rfm_cell in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from rfm_segmentation;



