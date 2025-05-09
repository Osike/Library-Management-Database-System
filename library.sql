-- Library Management System Database
-- This SQL script creates all necessary tables with proper constraints and relationships

-- Create database
CREATE DATABASE IF NOT EXISTS LibraryManagementSystem;
USE LibraryManagementSystem;

-- Members table (people who can borrow books)
CREATE TABLE Members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    date_of_birth DATE,
    membership_date DATE NOT NULL,
    membership_status ENUM('Active', 'Expired', 'Suspended') DEFAULT 'Active',
    CONSTRAINT chk_email CHECK (email LIKE '%@%.%')
);

-- Authors table (book authors)
CREATE TABLE Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year YEAR,
    death_year YEAR,
    nationality VARCHAR(50),
    biography TEXT,
    CONSTRAINT chk_life_years CHECK (death_year IS NULL OR birth_year IS NULL OR death_year >= birth_year)
);

-- Publishers table
CREATE TABLE Publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    address VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(100),
    founding_year YEAR,
    CONSTRAINT chk_pub_email CHECK (email LIKE '%@%.%')
);

-- Books table
CREATE TABLE Books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    publisher_id INT,
    publication_year YEAR,
    edition INT DEFAULT 1,
    page_count INT,
    language VARCHAR(30),
    description TEXT,
    category VARCHAR(50),
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id),
    CONSTRAINT chk_isbn CHECK (LENGTH(isbn) >= 10),
    CONSTRAINT chk_page_count CHECK (page_count > 0)
);

-- Book-Author relationship (M-M)
CREATE TABLE BookAuthors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    contribution_type VARCHAR(50) DEFAULT 'Primary Author',
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES Authors(author_id) ON DELETE CASCADE
);

-- BookCopies table (physical copies of books)
CREATE TABLE BookCopies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    acquisition_date DATE NOT NULL,
    condition ENUM('New', 'Good', 'Fair', 'Poor', 'Lost') DEFAULT 'Good',
    location VARCHAR(50) NOT NULL,
    status ENUM('Available', 'Checked Out', 'Reserved', 'Lost', 'Removed') DEFAULT 'Available',
    last_checkout_date DATE,
    CONSTRAINT fk_copy_book FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE
);

-- Loans table (book checkouts)
CREATE TABLE Loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    checkout_date DATETIME NOT NULL,
    due_date DATETIME NOT NULL,
    return_date DATETIME,
    late_fee DECIMAL(10,2) DEFAULT 0.00,
    status ENUM('Active', 'Returned', 'Overdue', 'Lost') DEFAULT 'Active',
    CONSTRAINT fk_loan_copy FOREIGN KEY (copy_id) REFERENCES BookCopies(copy_id),
    CONSTRAINT fk_loan_member FOREIGN KEY (member_id) REFERENCES Members(member_id),
    CONSTRAINT chk_due_date CHECK (due_date > checkout_date),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= checkout_date)
);

-- Reservations table
CREATE TABLE Reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiration_date DATETIME NOT NULL,
    status ENUM('Pending', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Pending',
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) REFERENCES Books(book_id),
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) REFERENCES Members(member_id),
    CONSTRAINT chk_reservation_dates CHECK (expiration_date > reservation_date)
);

-- Fines table
CREATE TABLE Fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    loan_id INT,
    amount DECIMAL(10,2) NOT NULL,
    issue_date DATE NOT NULL,
    payment_date DATE,
    status ENUM('Pending', 'Paid', 'Waived') DEFAULT 'Pending',
    reason VARCHAR(200) NOT NULL,
    CONSTRAINT fk_fine_member FOREIGN KEY (member_id) REFERENCES Members(member_id),
    CONSTRAINT fk_fine_loan FOREIGN KEY (loan_id) REFERENCES Loans(loan_id),
    CONSTRAINT chk_fine_amount CHECK (amount >= 0),
    CONSTRAINT chk_payment_date CHECK (payment_date IS NULL OR payment_date >= issue_date)
);

-- Staff table (library employees)
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    position VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    supervisor_id INT,
    CONSTRAINT fk_staff_supervisor FOREIGN KEY (supervisor_id) REFERENCES Staff(staff_id),
    CONSTRAINT chk_staff_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_salary CHECK (salary >= 0)
);

-- LibraryBranches table
CREATE TABLE LibraryBranches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    opening_hours VARCHAR(100),
    manager_id INT,
    CONSTRAINT fk_branch_manager FOREIGN KEY (manager_id) REFERENCES Staff(staff_id),
    CONSTRAINT chk_branch_email CHECK (email IS NULL OR email LIKE '%@%.%')
);

-- Add branch_id to BookCopies table (added after LibraryBranches exists)
ALTER TABLE BookCopies
ADD COLUMN branch_id INT NOT NULL AFTER copy_id,
ADD CONSTRAINT fk_copy_branch FOREIGN KEY (branch_id) REFERENCES LibraryBranches(branch_id);

-- Add branch_id to Staff table (added after LibraryBranches exists)
ALTER TABLE Staff
ADD COLUMN branch_id INT NOT NULL AFTER supervisor_id,
ADD CONSTRAINT fk_staff_branch FOREIGN KEY (branch_id) REFERENCES LibraryBranches(branch_id);

-- Add indexes for performance
CREATE INDEX idx_books_title ON Books(title);
CREATE INDEX idx_books_isbn ON Books(isbn);
CREATE INDEX idx_members_name ON Members(last_name, first_name);
CREATE INDEX idx_members_email ON Members(email);
CREATE INDEX idx_loans_member ON Loans(member_id);
CREATE INDEX idx_loans_copy ON Loans(copy_id);
CREATE INDEX idx_loans_dates ON Loans(checkout_date, due_date, return_date);
CREATE INDEX idx_copies_book ON BookCopies(book_id);
CREATE INDEX idx_copies_status ON BookCopies(status);
CREATE INDEX idx_reservations_book ON Reservations(book_id);
CREATE INDEX idx_reservations_member ON Reservations(member_id);


