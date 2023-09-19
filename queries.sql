select
count(customer_id) as customers_count /*запрос считает общее количество покупателей из таблицы customers по customer_id*/
from customers;

select /*отчет с продавцами у которых наибольшая выручка*/
concat(first_name, ' ', last_name) as name,
count(quantity) as operations,
sum(quantity) as income
from sales
inner join employees on employee_id = sales_person_id 
group by employee_id, quantity
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

