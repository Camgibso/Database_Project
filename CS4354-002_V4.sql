/*###########################################################
#	Authors: Cameron Gibson, Anish Chhetri, 				#
#		Garret Mbaku, Jeremy Wenzel, Rhett Calvert			#
#	Topic: Student Enrollment Database 						#
###########################################################*/

--Create database and tables
CREATE DATABASE IF NOT EXISTS groupProject;
USE groupProject;

CREATE TABLE department(
   departmentName VARCHAR(30) NOT NULL,
   location VARCHAR(30) NULL,
   PRIMARY KEY (departmentName)
  );

CREATE TABLE instructor (
	instructorId INT NOT NULL,
	fName varchar(30),
	lName varchar(30),
	email varchar(30),
	departmentName varchar(30),
	PRIMARY KEY (instructorId),
    Foreign Key(departmentName) 
		REFERENCES department(departmentName) ON DELETE CASCADE
  	);

CREATE TABLE Student (  
	rNumber INT NOT NULL,
	fName varchar(30),
	lName varchar(30),
	email varchar(30),
	PRIMARY KEY (rNumber)
	);

CREATE TABLE Course(
	courseId INT NOT NULL, 
	term char(10), 
	courseName varchar(30), 
	departmentName varchar(30), 
	instructorId INT,
	PRIMARY KEY(courseId),
	FOREIGN KEY(departmentName) 
		REFERENCES department(departmentName) ON DELETE CASCADE,
	FOREIGN KEY(instructorId) 
		REFERENCES instructor(instructorId) ON DELETE CASCADE
	);

CREATE TABLE course_Student(
	courseId INT NOT NULL,
	rNumber INT NOT NULL,
	Primary Key(courseId, rNumber),
	FOREIGN KEY(courseId) 
		REFERENCES course(courseId) ON DELETE CASCADE,
	FOREIGN KEY(rNumber) 
		REFERENCES student(rNumber) ON DELETE CASCADE
	);

CREATE TABLE student_log
(
	rNumber INT NOT NULL,
	fName varchar(30) NOT NULL,
	lName varchar(30) NOT NULL,
    actionEvent varchar (30) NOT NULL,
    timeAt DATETIME NOT NULL
);

CREATE TABLE student_course_log
(
    rNumber INT NOT NULL,
    courseId INT NOT NULL,
    actionEvent varchar (30) NOT NULL,
    timeAt DATETIME NOT NULL
);

--Populate Departments
--truncate groupproject.department;
INSERT INTO department(departmentName, location)
	VALUES("Computer Science", "902 Boston Ave"),
			("Mathematics", "1108 Memorial Circle"),
			("Human Sciences", "1301 Akron Ave");
SELECT * FROM groupproject.department;

--Populate Instructors
--truncate groupproject.instructor;
INSERT INTO instructor(instructorId, fName, lName, email, departmentName) 
			VALUES(1, "Richard", "Watson", "richard.watson@ttu.edu", "Computer Science"),
            (2, "Yong", "Chen", "Yong.Chen@ttu.edu", "Computer Science"),
            (3, "Abdul", "Serwadda", "abdul.serwadda@ttu.edu", "Computer Science"),
            (4, "Lawrence", "Schovanec", "Lawrence.Schovanec@ttu.edu", "Mathematics"),
            (5, "Robbie", "Brown", "Robbie.Brown@ttu.edu", "Human Sciences");
SELECT * FROM groupproject.instructor;
            
--Populate Students
INSERT INTO student(rNumber, fName, lName, email) 
			VALUES(12345670, "Cameron", "Gibson", "cameron.gibson@ttu.edu"),
            (12345671, "Anish", "Chhetri", "Anish.Chhetri@ttu.edu"),
            (12345672, "Garret", "Mbaku", "Garret.Mbaku@ttu.edu"),
            (12345673, "Jeremy", "Wenzel", "Jeremy.Wenzel@ttu.edu"),
            (12345674, "Brianna", "White", "Brianna.White@ttu.edu"),
            (12345675, "Rhett", "Thompson", "Rhett.Thompson@gmail.com");
SELECT * FROM groupproject.student;

--Populate Courses
--truncate groupproject.
INSERT INTO course(courseId, term, courseName, departmentName, instructorId) 
			VALUES (1, "Fall", "Algorithms", "Computer Science", 1),
					(2, "Fall", "Discrete Math", "Computer Science", 1),
					(3, "Fall", "Operating Systems", "Computer Science", 2),
                    (4, "Spring", "Database Management", "Computer Science", 3),
                    (5, "Spring", "Differential Equations", "Mathematics", 4),
                    (6, "Spring", "Basket Weaving", "Human Sciences", 5);
SELECT * FROM groupproject.course;

--Populate course_Student
--Use truncate to clear existing values
--truncate groupproject.course_Student;
INSERT INTO course_Student(courseId, rNumber) 
			VALUES (1, 12345670), (2, 12345670), (3, 12345670), (4, 12345670), (5, 12345670), (6, 12345670),
            (2, 12345671), (3, 12345671), (5, 12345671), (6, 12345671),
            (1, 12345672), (2, 12345672), (3, 12345672), (4, 12345672), (6, 12345672),
            (1, 12345673), (2, 12345673), (4, 12345673),
            (1, 12345674), (3, 12345674), (5, 12345674), (6, 12345674),
            (1, 12345675), (2, 12345675), (3, 12345675), (6, 12345675);
SELECT * FROM groupproject.course_Student;
--Lines broken up according to rNumber

--Triggers that enter deleted values into a log table
delimiter |
--This trigger saves inserted/deleted students details into a log table
CREATE TRIGGER student_deleted
	AFTER DELETE ON student
    FOR EACH ROW
BEGIN
	INSERT INTO student_log VALUES (OLD.rNumber, OLD.fName, OLD.lName, 'DELETED', NOW());
END;

CREATE TRIGGER student_inserted
	AFTER INSERT ON student
    FOR EACH ROW
BEGIN
	INSERT INTO student_log VALUES (NEW.rNumber, NEW.fName, NEW.lName, 'INSERTED', NOW());
END;
|

delimiter |
--These trigger saves added/dropped courses into a log table
CREATE TRIGGER course_added
	AFTER INSERT ON course_student
    FOR EACH ROW
BEGIN
	INSERT INTO student_course_log VALUES (NEW.rNumber, NEW.courseId, "ADDED", NOW());
END;

CREATE TRIGGER course_dropped
	AFTER DELETE ON course_student
    FOR EACH ROW
BEGIN
	INSERT INTO student_course_log VALUES (OLD.rNumber, OLD.courseId, "DROPPED", NOW());
END;
|

--Testing deletion from student log
--Shows the rNumber in the table prior to deletion
SELECT * FROM groupproject.student;
DELETE FROM groupproject.student
	WHERE rNumber = 12345675;
-- Show the rNumber is gone from the Student table and course_Student
-- and has been inserted into student_log
SELECT * FROM groupproject.student;
SELECT * FROM student_log;
SELECT * FROM course_student;

--Testing a student dropping a class (Cameron drops 1st class) 
SELECT * FROM groupproject.course_student
	WHERE rnumber = 12345670;
DELETE FROM groupproject.course_student
	WHERE rNumber = 12345670 AND courseId = 1;
--If the above gives you an error, uncomment and run this and it will work
--SET SQL_SAFE_UPDATES = 0;

--Shows course dropped and moved to the drop log
SELECT * FROM groupproject.course_student
	WHERE rnumber = 12345670;
SELECT * FROM student_course_log;

/*
A stored procedure with condition handling for:
- insertion of a null value for a PK
- Insertion of a dupe primary key 
*/
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `insertNewStudents`()
BEGIN
		DECLARE duplicate_entry_for_rNumber TINYINT DEFAULT FALSE;
        DECLARE null_entry_for_rNumber TINYINT DEFAULT FALSE;
        BEGIN
			DECLARE CONTINUE HANDLER FOR 1062
				SET duplicate_entry_for_rNumber = TRUE;
			DECLARE CONTINUE HANDLER FOR 1048
				SET null_entry_for_rNumber = TRUE;
			
            --New Student details
			INSERT INTO groupproject.student(rNumber, fName, lName, email) 
				VALUES(12345676, "Zach", "Gibson", "Zach.gibson@ttu.edu"),
					(12345677, "Austin", "Gibson", "Austin.Gibson@ttu.edu"),
					(12345678, "Colin", "Mbaku", "Colin.Mbaku@ttu.edu");
			INSERT INTO course_Student(courseId, rNumber) 
				VALUES (1, 12345676), (2, 12345676), (3, 12345676), (4, 12345676),
					(1, 12345677), (2, 12345677), (5, 12345677), (6, 12345677),
                    (2, 12345678), (3, 12345678), (5, 12345678), (6, 12345678);
		END;
		IF duplicate_entry_for_rNumber = TRUE THEN
			SELECT 'You must enter a unique rNumber' 
				AS message;
		ELSEIF null_entry_for_key = TRUE THEN
			SELECT 'You must enter a non-null rNumber' 
				AS message;
		ELSE
			SELECT 'Insert successful' 
				AS message;
		END IF;
END//

CALL `insertNewStudents`();
--Showing the values were inserted and trigger table updated
SELECT * FROM groupproject.student;
SELECT * FROM groupproject.course_Student;
SELECT * FROM groupproject.student_log;
SELECT * FROM groupproject.student_course_log;

-- View where a student can see the their name, email, and courses they're signed up for
DROP VIEW IF EXISTS `studentView`;
CREATE VIEW `studentView` 
	AS SELECT s.fName, s.lName, s.email, c.courseName 
	FROM student s, course c, course_student h
	WHERE h.rNumber = s.rNumber AND h.courseID = c.courseID;
SELECT * FROM groupproject.studentview;

-- view which classes an instructor teaches for
DROP VIEW IF EXISTS `instructorView`;
CREATE VIEW `instructorView`
	AS SELECT i.lName, i.fName, i.email, c.courseName
	FROM instructor i, course c
	WHERE i.instructorID = c.instructorID;
SELECT * FROM groupproject.instructorView;

-- view where a class is located
DROP VIEW IF EXISTS `courseLocation`;
CREATE VIEW `courseLocation`
	AS SELECT c.courseName, c.departmentName, c.instructorId, e.lName, d.location
	FROM department d, course c, instructor e
	WHERE d.departmentName = c.departmentName;
SELECT * FROM groupproject.courseLocation;

/*indexes*/
-- custom indexes for tables to enchance prefromance on data retrieval
CREATE INDEX indx_courseName
ON course (courseName);

CREATE INDEX indx_lName
ON student_log (lName);

CREATE INDEX indx_StudentlastName
ON student (lName);

CREATE INDEX indx_insLastName
ON instructor (lName);

CREATE INDEX indx_Deptlocation
ON department (location);

CREATE INDEX indx_rNumb
ON course_student (rNumber);

CREATE INDEX indx_courseID
ON student_course_log (courseId);