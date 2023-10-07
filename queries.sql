select
count(customer_id) as customers_count /*запрос считает общее количество покупателей из таблицы customers по customer_id*/
from customers;

select /*отчет с продавцами у которых наибольшая выручка*/
concat(first_name, ' ', last_name) as name,
count(quantity) as operations,
sum(quantity) as income
from sales
inner join employees on employee_id = sales_person_id 
group by name
order by income desc
limit 10;

with tab as(
select /*отчет с информацией о средней выручке продавцов*/
distinct(concat(first_name, ' ', last_name)) as name,
avg(quantity) over (partition by concat(first_name, ' ', last_name)) as average_income
from sales
inner join employees on employee_id = sales_person_id
)
select /*округление до целого+информация о продавцам, у которых сред выручка за сделку меньше средней выручки по всем продавцам*/
name,
round(average_income,0)
from tab
where average_income < 
(
select /*средняя выручка по всем продавцам*/
avg(quantity) 
from sales
)
order by average_income; /*сортировка по возрастанию средней выручки*/


with tab as(
select /*отчет с информацией о продажах по продавцам и дням недели*/
distinct(concat(first_name, ' ', last_name)) as name,
to_char(sale_date, 'd') as weekdate, /*порядковый номер дня недели для сортировки*/
to_char(sale_date, 'day') as weekday,
sum(quantity) over (partition by concat(first_name, ' ', last_name), to_char(sale_date, 'd')) as income
from sales
inner join employees on employee_id = sales_person_id
order by weekdate, name
)
select /*округление до целого+оставляем только имена дней недели отсортированные по США*/
name,
weekday,
round(income,0) as income
from tab;


with tab as(
select /*сортируем данные по возрастным группам*/
case 
	when age between '16' and '25' then '16-25'
	when age between '26' and '40' then '26-40'
	else '40+'
end as age_category,
age
from customers
)
select  /*считаем кол-во людей по возрастным группам*/
distinct(age_category),
count(age) over (partition by age_category) as count
from tab
order by age_category;



with tab as(
select 
to_char(cast(sale_date as date),'YYYY-MM') as date, /*приводим данные в вид ГОД-МЕСЯЦ*/
count(customers.customer_id) over (partition by to_char(cast(sale_date as date),'YYYY-MM')) as total_customers, /*считаем кол-во покупателей по дате покупки*/
quantity
from sales 
inner join customers on customers.customer_id = sales.customer_id /*соединяем таблицы*/
group by date, customers.customer_id, quantity
order by date
)
select date, /*считаем сумму продаж по всем поупателям по месяцам*/
total_customers,
sum(quantity) as income
from tab
group by date, total_customers
order by date

with tab as( 
select 
row_number() over (partition by sales.customer_id order by sale_date) as row_num, /*пронумеровали покупателей по датам покупок*/
sales.customer_id,
sale_date,
price,
sales_person_id
from sales
inner join products on sales.product_id = products.product_id 
where price = 0 /*выбрали акционные покупки*/
group by sale_date, sales.customer_id, price, sales_person_id
),
tab2 as(
select 
concat(customers.first_name, ' ', customers.last_name) as customer, /*обозначили имена и фамилии покупателей*/
tab.customer_id,
sale_date,
sales_person_id
from tab
inner join customers on tab.customer_id = customers.customer_id
where row_num = 1 /*отфильтровали первые акционные покупки по покупателям*/
order by tab.customer_id
)
select 
customer,
sale_date,
concat(employees.first_name, ' ', employees.last_name) as seller /*обозначили имена и фамилии продавцов акционных товаров*/
from tab2
inner join employees on tab2.sales_person_id = employees.employee_id

