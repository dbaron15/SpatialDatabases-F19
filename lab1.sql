-- Lab 1 Task 2 Q1
SELECT count(au_id) AS AuthorCount, avg(au_salary::numeric::float8)::numeric::money AS AverageSalary, au_subject AS AuthorSubject
FROM lab1."Authors"
GROUP BY au_subject;

-- Lab 1 Task 2 Q2
SELECT count(au_id) AS AuthorCount, avg(au_salary::numeric::float8)::numeric::money AS AverageSalary, au_state AS AuthorState
FROM lab1."Authors"
GROUP BY au_state;

-- Lab 1 Task 2 Q3
SELECT count(au_id) AS AuthorCount, avg(au_salary::numeric::float8)::numeric::money AS AverageSalary
FROM lab1."Authors"
WHERE au_sex = 'F' AND au_subject = 'Sci-fi';

-- Lab 1 Task 2 Q4
SELECT count(au_id) AS AuthorCount, avg(au_salary::numeric::float8)::numeric::money AS AverageSalary, au_state AS State
FROM lab1."Authors"
WHERE au_sex = 'M' AND au_subject = 'Sci-fi'
GROUP BY au_state;

-- Lab 1 Task 2 Q5
SELECT "Authors".au_lname, "Authors".au_fname, "BookAuthor".au_id, "BookAuthor".title_id, "Books".title
FROM lab1."Authors"
INNER JOIN (lab1."Books" 
			INNER JOIN lab1."BookAuthor" ON lab1."Books".title_id = lab1."BookAuthor".title_id) 
			ON lab1."Authors".au_id = lab1."BookAuthor".au_id;