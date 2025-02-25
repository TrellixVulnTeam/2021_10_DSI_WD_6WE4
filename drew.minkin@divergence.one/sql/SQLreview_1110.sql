/*
Syntax

Data Engineering
====================
DDL - Data Definition Language
	CREATE (TABLE,INDEX, VIEW PROCEDURE, DEFAULT)
DCL - Data Control Language
	GRANT...ON ...TO
 	DENY... ON ...TO
DML - Data Manipulation Language
	INSERT
	DELETE
	UPDATE - INSERT/DELETE
	SELECT ... INTO


Data Analysis
=============
DQL - Data Query Language
	
	SELECT
		<col list>
		<aggregate>
	FROM
		<tbl_list> and/or JOIN clauses
	WHERE
		<row_filter>
	GROUP BY
		<tuple>
	HAVING
		<aggregate_filter>
*/

/*

When to use SQL vs Power Query
1. Data is too big to import
2. Multiple types of apps need access to insights
*/
/*
Analytic Queries
====================
Level One � basic  
What does a typical Sales Order detail look like? 
*/
SELECT 
	COUNT(*) 
FROM 
	Instructors
--25 Courses
--100 StudentCourses
--8 dept
--43 Students
--16 Instructors

SELECT 
	*
FROM
	Tuition
	/*
576.875
288.375
384.50
	*/
/*
Level Two � simple aggregation 
What is the percentage of sales per country? 
[dbo].[Courses]
	[CourseUnits]
[dbo].[Instructors]
	[HireDate]
	[AnnualSalary]
	[DepartmentChairman]
[dbo].[Students]
	[GraduationDate]
	[EnrollmentDate]
	*/
/*
How many courses are in each department?
DepartmentName	(No column name)
Business	7
Education	3
English	4
Mathematics	3
Music	2
Science	4
Sociology	2
*/
CREATE VIEW SchedulableClasses
AS
	SELECT
	--tuple/grouping set
		d.DepartmentName
	--aggregate & column name
		,count(c.DepartmentID) as NumberOfClasses
	FROM
	--table alias
		[dbo].[Departments] d
	INNER JOIN
		[dbo].[Courses] c
	on
			d.DepartmentID
		=
			c.DepartmentID
	GROUP BY
		d.DepartmentName
select * from SchedulableClasses
/*
What department has no classes on the schedule?
--Political Science
*/
SELECT
		d.DepartmentName
	FROM
		[dbo].[Departments] d
	LEFT OUTER JOIN
		dbo.SchedulableClasses sc
	on
			d.DepartmentName
		=
			sc.DepartmentName
	WHERE
		sc.NumberOfClasses IS NULL

/*
What is the distribution of enrollments per department?
*/
--raw numbers
CREATE VIEW EnrollmentBase
AS
	SELECT
		TOP 100 PERCENT
	--tuple/grouping set
		d.DepartmentName
	--aggregate & column name
		,count(sc.StudentID) as Enrollment
		,count(distinct sc.StudentID) as [Distinct Students]
	FROM
	--table alias
		[dbo].[Departments] d
	INNER JOIN
		[dbo].[Courses] c
	on
			d.DepartmentID
		=
			c.DepartmentID
	INNER JOIN
		[dbo].[StudentCourses] sc
	on
			c.CourseID
		=
			sc.CourseID
	GROUP BY
		d.DepartmentName
	ORDER BY
		--positional, column name or aggregate calc
		--sum(sc.StudentID)
		3
		DESC

--percentage
With te
AS
(
	SELECT 
		CAST(
			COUNT(*) as decimal --TotalEnrollment
			) 
			AS Qty
	FROM 
		[dbo].[StudentCourses] 
)
SELECT 
		DepartmentName
		,
		ROUND(
			(Enrollment
			/te.Qty) 
			* 100
			,2)
FROM EnrollmentBase, te

/*
what students are full time vs part time?
	->
	what $ each department contributes
	*/
--student enrollment
CREATE VIEW EnrollmentDistribution
AS
	WITH QtyEnrollBase
	AS
	(
	SELECT
			sc.StudentID
			,COUNT(*) QtyEnrollments
		FROM
			[dbo].[StudentCourses] sc
		GROUP BY
			sc.StudentID
	)
	SELECT
		QtyEnrollments,
		COUNT(*) NumStudents
	FROM
		QtyEnrollBase
	GROUP BY 
		QtyEnrollments
	--Part Time - QtyEnrollments = 2 or 3
CREATE VIEW StudentEnrollment
AS
WITH QtyEnrollBase
AS
(
SELECT
		sc.StudentID
		,COUNT(*) QtyEnrollments
	FROM
		[dbo].[StudentCourses] sc
	GROUP BY
		sc.StudentID
)
SELECT 
	StudentID
	,
		CASE
			WHEN
				QtyEnrollments = 4
			THEN 'FullTime'
			ELSE 'PartTime'
		END
			as EnrollmentStatus
FROM
	QtyEnrollBase


ALTER TABLE Students ADD EnrollmentStatus varchar(20)

UPDATE Students
SET EnrollmentStatus = se.EnrollmentStatus
FROM Students s
JOIN StudentEnrollment se
ON s.StudentID = se.StudentID
/*
Level Three � simple calculations and statistical profiles 
What is the distribution of basket revenue sizes? 
What is the percentage change in sales over time? 
*/
CREATE VIEW  EnrolledStudents
AS
SELECT * FROM Students WHERE EnrollmentStatus IS NOT NULL

/*
Contribution per Student -> Contribution per Department
*/

SELECT * FROM Tuition

/*
Contribution per Student 
:)		 Allocation of Enrollment Cost  Per Course (PT) 
:)		+Allocation of Enrollment Cost  Per Course (FT)

:)		+Per Course Cost (PerUnitCost * CourseUnits)
*/

--Student enrollment per Department
--StudentID,DepartmentName,TotalUnits
--select * from EnrollmentBaseContribution

CREATE VIEW EnrollmentBaseContribution
AS
	SELECT
		TOP 100 PERCENT
	--tuple/grouping set
		d.DepartmentName
		,sc.StudentID
	--aggregate & column name
		,sum(c.CourseUnits) as [TotalUnits]
		,sum(c.CourseUnits*Tuition.PerUnitCost) as DeptBaseContribution
	FROM Tuition,
	--table alias
		[dbo].[Departments] d
	INNER JOIN
		[dbo].[Courses] c
	on
			d.DepartmentID
		=
			c.DepartmentID
	INNER JOIN
		[dbo].[StudentCourses] sc
	on
			c.CourseID
		=
			sc.CourseID
	GROUP BY
		d.DepartmentName
		,sc.StudentID
	ORDER BY
		--positional, column name or aggregate calc
		--sum(sc.StudentID)
			sc.StudentID ASC
			,d.DepartmentName ASC
			,TotalUnits DESC

/*
Department
TotalContribution
PctofTotal
*/
CREATE VIEW DepartmentTotalContribution
AS
WITH
--StudentID,EnrollmentCost
	NonClassCost
		AS
			(SELECT
				es.StudentID
				,
				CASE
					WHEN
						EnrollmentStatus = 'FullTime'
					THEN t.FullTimeCost
					ELSE t.PartTimeCost
				END
					as EnrollmentBaseCost
			FROM 
				EnrolledStudents es
				,Tuition t
			)
,
	denominator
		AS
			(SELECT 
				StudentID 
				, SUM(DeptBaseContribution) TotalContribution
				FROM EnrollmentBaseContribution
			GROUP BY StudentID)
,
	contribution_raw
		AS	
		(
		SELECT 
			'NonTuition' as CostType
			,ebc.StudentID
			,ebc.DepartmentName
			,
				(ebc.DeptBaseContribution
				/d.TotalContribution)
				* n.EnrollmentBaseCost as DeptContribution
			FROM 
				EnrollmentBaseContribution ebc
			JOIN 
				denominator d 
			on
				d.StudentID = ebc.StudentID
			JOIN
				NonClassCost n
			on
				d.StudentID = n.StudentID
		UNION
		SELECT 
			'Tuition' as CostType
			,ebc.StudentID
			,ebc.DepartmentName
			,ebc.DeptBaseContribution
			FROM 
				EnrollmentBaseContribution ebc
		)
	,deptcontrib
		AS
			(
				SELECT
					DepartmentName
					,SUM(DeptContribution) DeptContribution
				FROM	
					contribution_raw
				GROUP BY 
					DepartmentName
			)
	,totalcontrib
		AS
			(
				SELECT
					SUM(DeptContribution) TotalContrib
				FROM	
					deptcontrib
			)
	SELECT
	TOP 100 PERCENT
		d.DepartmentName
		,d.DeptContribution
		,
			(d.DeptContribution
				/
				t.TotalContrib) as PctContribution
		from 
			deptcontrib d
			, totalcontrib t
		order by 
		PctContribution DESC
/*
Instructor Net Cost
= AnnualSalary - InstructorDeptContribution
:)		1. Instructor,Department,NumUnits(NumStudents*CourseUnits)
:)		2. Instructor,Pct of Units by Dept
			Instructor,Dept,PctofUnits
3. Instructor,Instructor Net Cost( Salary - Contribution)
*/
CREATE VIEW InstructorNumUnits
AS SELECT
	i.FirstName
	+' '
	+i.LastName
		AS	Instructor
	,d.DepartmentName
	,SUM(c.CourseUnits) as NumUnits
FROM
	[dbo].[Instructors] i
JOIN
	[dbo].[Courses] c
on
		i.InstructorID
	=
		c.InstructorID
JOIN
	[dbo].[StudentCourses] sc
on
		c.CourseID
	=
		sc.CourseID
JOIN
	[dbo].[Departments] d
	on
			d.DepartmentID
		=
			c.DepartmentID
GROUP BY
	i.FirstName
	+' '
	+i.LastName
	,d.DepartmentName

CREATE VIEW InstructorContribution
AS
WITH agg
AS
	(SELECT
	DepartmentName
	,SUM(NumUnits) TotalUnits
	from InstructorNumUnits
	GROUP BY DepartmentName)
, instructor_contribut
AS
	(
		SELECT
			i.Instructor
			,i.DepartmentName
			, i.NumUnits/(a.TotalUnits*1.0) as PctUnits
		FROM	
			InstructorNumUnits i
		JOIN
			agg a
		ON 
				i.DepartmentName
			=
				a.DepartmentName
	)
/*
Instructor
Dept
Salary
Contribution
% of Salary Covered by Tuition
*/
SELECT
TOP 100 PERCENT
ic.Instructor
,dtc.DepartmentName
,ic.PctUnits * dtc.DeptContribution as SalaryCovered
,
	((ic.PctUnits * dtc.DeptContribution)
	/i.AnnualSalary) * 100 as PctSalaryCovered
from DepartmentTotalContribution dtc
join instructor_contribut ic
 on 
	dtc.DepartmentName
 =
	ic.DepartmentName
right join Instructors i
on 	i.FirstName
	+' '
	+i.LastName
= ic.Instructor
order by PctSalaryCovered Desc



/****** Object:  Table [dbo].[Courses]    Script Date: 11/10/2021 9:05:03 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Courses](
	[CourseID] [int] IDENTITY(1,1) NOT NULL,
	[CourseNumber] [int] NULL,
	[CourseDescription] [varchar](50) NOT NULL,
	[CourseUnits] [int] NOT NULL,
	[DepartmentID] [int] NOT NULL,
	[InstructorID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CourseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[CourseNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

USE [MurachCollege]
GO

/****** Object:  Index [PK__Courses__C92D7187A6836724]    Script Date: 11/10/2021 9:15:07 AM ******/
ALTER TABLE [dbo].[Courses] ADD PRIMARY KEY CLUSTERED 
(
	[CourseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO



ALTER TABLE [dbo].[Courses] ADD  DEFAULT ((3)) FOR [CourseUnits]
GO

ALTER TABLE [dbo].[Courses]  WITH CHECK ADD FOREIGN KEY([DepartmentID])
REFERENCES [dbo].[Departments] ([DepartmentID])
GO

ALTER TABLE [dbo].[Courses]  WITH CHECK ADD FOREIGN KEY([InstructorID])
REFERENCES [dbo].[Instructors] ([InstructorID])
GO

USE [MurachCollege]
GO

ALTER TABLE [dbo].[Instructors]  WITH CHECK ADD FOREIGN KEY([DepartmentID])
REFERENCES [dbo].[Departments] ([DepartmentID])
GO

WITH
--StudentID,EnrollmentCost
	NonClassCost
		AS
			(SELECT
				es.StudentID
				,
				CASE
					WHEN
						EnrollmentStatus = 'FullTime'
					THEN t.FullTimeCost
					ELSE t.PartTimeCost
				END
					as EnrollmentBaseCost
			FROM 
				EnrolledStudents es
				,Tuition t
			)
,
	denominator
		AS
			(SELECT 
				StudentID 
				, SUM(DeptBaseContribution) TotalContribution
				FROM EnrollmentBaseContribution
			GROUP BY StudentID)
--,
--	contribution_raw
--		AS	
--		(
		SELECT 
			'NonTuition' as CostType
			,ebc.StudentID
			,ebc.DepartmentName
			,
				(ebc.DeptBaseContribution
				/d.TotalContribution)
				* n.EnrollmentBaseCost as DeptContribution
			FROM 
				EnrollmentBaseContribution ebc
			JOIN 
				denominator d 
			on
				d.StudentID = ebc.StudentID
			JOIN
				NonClassCost n
			on
				d.StudentID = n.StudentID
		UNION
		SELECT 
			'Tuition' as CostType
			,ebc.StudentID
			,ebc.DepartmentName
			,ebc.DeptBaseContribution
			FROM 
				EnrollmentBaseContribution ebc
		)
	,deptcontrib
		AS
			(
				SELECT
					DepartmentName
					,SUM(DeptContribution) DeptContribution
				FROM	
					contribution_raw
				GROUP BY 
					DepartmentName
			)
	,totalcontrib
		AS
			(
				SELECT
					SUM(DeptContribution) TotalContrib
				FROM	
					deptcontrib
			)
	SELECT
	TOP 100 PERCENT
		d.DepartmentName
		,d.DeptContribution
		,
			(d.DeptContribution
				/
				t.TotalContrib) as PctContribution
		from 
			deptcontrib d
			, totalcontrib t
		order by 
		PctContribution DESC
