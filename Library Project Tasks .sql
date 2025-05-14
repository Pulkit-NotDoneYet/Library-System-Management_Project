SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM return_status;
SELECT * FROM issued_status;
SELECT * FROM members;

--Project Task
--Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books

--Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101'
SELECT * FROM members

--Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121'
SELECT * FROM issued_status

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'

--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT issued_emp_id,
       COUNT(issued_id) AS total_books
FROM issued_status
GROUP BY 1
HAVING COUNT(issued_id) > 1

--CTAS
--Task 6: Create Summary Tables: Use CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_cnts
AS
SELECT a.isbn, a.book_title, COUNT(b.issued_id)
FROM books AS a
INNER JOIN issued_status AS b
ON a.isbn = b.issued_book_isbn
GROUP BY 1,2;

SELECT * FROM book_cnts

--Task 7. Retrieve All Books in a Specific Category(Classic;
SELECT*
FROM books
WHERE category = 'Classic'

--Task 8: Find Total Rental Income by Category:
SELECT a.category,
       SUM(a.rental_price),
	   COUNT(*)
FROM books AS a
INNER JOIN issued_status AS b
ON a.isbn = b.issued_book_isbn
GROUP BY 1

--Task 9: List Members Who Registered in the Last 180 Days:
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days'

INSERT INTO members(member_id, member_name, member_address, reg_date)
VALUES
('C120', 'Gabo Saturno', '145 Pine St', '2025-02-01'),
('C121', 'Tom Merrick', '689 Maple St', '2024-12-31')

--Task 10: List Employees with Their Branch Manager's Name and their branch details:
SELECT a.*, b.manager_id, e.emp_name AS manager_name
FROM employees AS a
INNER JOIN branch AS b
ON a.branch_id = b.branch_id
JOIN employees AS e
ON b.manager_id = e.emp_id

--Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 7 USD:
CREATE TABLE books_price_greater_than_seven
AS
SELECT * FROM books
WHERE rental_price > 7
SELECT * FROM books_price_greater_than_seven

--Task 12: Retrieve the List of Books Not Yet Returned
SELECT DISTINCT issued_book_name
FROM issued_status AS a
LEFT JOIN return_status AS b
ON a.issued_id = b.issued_id
WHERE return_id IS NULL


ALTER TABLE return_status 
ADD COLUMN book_quality VARCHAR(15) DEFAULT('Good');

UPDATE return_status 
SET book_quality = 'Damaged'
WHERE issued_id 
    IN ('IS112', 'IS117', 'IS118');
SELECT * FROM return_status
 
--Advanced SQL Operations
/*Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.*/
SELECT c.member_id, c.member_name, b.book_title, a.issued_date, CURRENT_DATE - issued_date AS overdue_days
FROM issued_status AS a
INNER JOIN books AS b
ON a.issued_book_isbn = b.isbn
INNER JOIN members AS c
ON a.issued_member_id = c.member_id
LEFT JOIN return_status AS d
ON a.issued_id = d.issued_id
WHERE 
     return_date IS NULL  
AND (CURRENT_DATE - issued_date) > 30 	 
ORDER BY 1

/*
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/
--Stored Procedures
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


-- Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');

/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.*/

SELECT * FROM branch;

SELECT * FROM issued_status;

SELECT * FROM employees;

SELECT * FROM return_status;

SELECT * FROM books;

CREATE TABLE branch_reports
AS
SELECT   b.branch_id, 
         b.manager_id,
		 SUM(bk.rental_price) AS total_revenue,
		 COUNT(a.issued_id) AS number_books_issued, 
		 COUNT(r.return_id) AS number_books_returned
FROM issued_status AS a
JOIN employees AS e
ON a.issued_emp_id = e.emp_id
JOIN branch AS b
ON e.branch_id = b.branch_id
LEFT JOIN return_status AS r
ON a.issued_id = r.issued_id
JOIN books AS bk
ON a.issued_book_isbn = bk.isbn
GROUP BY 1, 2

SELECT * FROM branch_reports

/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 15 months.*/
CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (
                    SELECT
                         DISTINCT issued_member_id
                    FROM issued_status
                    WHERE
                         issued_date >= CURRENT_DATE - INTERVAL '15 months'
                    );
SELECT * FROM active_members

--Task 17: Find Employees with the Most Book Issues Processed
--Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

SELECT e.emp_name, b.*, COUNT(a.issued_id) AS no_books_issued
FROM issued_status AS a
JOIN employees AS e
ON a.issued_emp_id = e.emp_id
JOIN branch AS b
ON e.branch_id = b.branch_id
GROUP BY 1, 2

--Task 18: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
--Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. The resulting table should show: Member ID, Number of overdue books, Total fines.
CREATE TABLE books_fines
AS
SELECT m.member_id, 
	m.member_name, 
	COUNT(member_id) AS books_overdue,
	SUM((CURRENT_DATE - (i.issued_date + INTERVAL '30 Days')::DATE) * 0.50) AS total_fines	
FROM members AS m
JOIN issued_status AS i
	ON i.issued_member_id = m.member_id
LEFT JOIN return_status AS r
	ON r.issued_id = i.issued_id
JOIN books AS b
	ON b.isbn = i.issued_book_isbn
WHERE return_date IS NULL 
	AND CURRENT_DATE - (i.issued_date + INTERVAL '30 Days')::DATE > 0
GROUP BY 1,2

SELECT * FROM books_fines

/*
Task 19: Stored Procedure Objective: 
Create a stored procedure to manage the status of books in a library system.
Description: Write a stored procedure that updates the status of a book in the library based on its issuance.
The procedure should function as follows: 
The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes').
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
-- all the variabable
    v_status VARCHAR(10);

BEGIN
-- all the code
    -- checking if book is available 'yes'
    SELECT 
        status 
        INTO
        v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN

        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books
            SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book records added successfully for book isbn : %', p_issued_book_isbn;


    ELSE
        RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
    END IF;
END;
$$

-- Testing The function
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8'





























