create table temp(
       num_col1 NUMBER,
       num_col2 NUMBER,
       char_col VARCHAR2(20)
);

DECLARE 
  x NUMBER := 100;
BEGIN
  for i in 1..10 loop
    if mod(i,2) = 0 then 
      insert into temp values (i,x,'i is even');
    else
      insert into temp values (i,x,'i is odd');
    end if;
    x := x + 100;
  end loop;
  commit;
END;

select * from; --order by num_col1;
drop table temp;
-------------------------------------------------------------------------
--Sample 2. Cursors
-------------------------------------------------------------------------
--The following example uses a cursor to select the five highest paid employees from the emp table.

CREATE TABLE emp (
       name varchar2(10),
       id number,
       salary number
       );
       
SELECT * FROM emp;
drop table emp;       
       
insert into emp (name,id,salary) values('KING',7839,5000);
insert into emp (name,id,salary) values('FORD',4595,3000); 
insert into emp (name,id,salary) values('SMITH',1235,2000); 
insert into emp (name,id,salary) values('BLAKE',4562,1000); 
insert into emp (name,id,salary) values('BAKOLAS',1015,10000); 
insert into emp (name,id,salary) values('ADAMS',9872,1250); 
insert into emp (name,id,salary) values('BRIAN',6452,4000); 
insert into emp (name,id,salary) values('THOMAS',2140,3000); 
insert into emp (name,id,salary) values('BILLIAN',6523,2500);    
insert into emp (name,id,salary) values('KLARIAN',4582,4000);    
insert into emp (name,id,salary) values('KSTIMBEIRO',7984,6000);    
insert into emp (name,id,salary) values('HAN',3541,3000);    
   

select name,id,salary from emp order by salary desc;

DECLARE
       CURSOR c1 IS 
       SELECT name,id,salary FROM emp 
       ORDER BY salary DESC;
           
       my_name emp.name%TYPE;
       my_id emp.id%TYPE;
       my_salary emp.salary%TYPE;      
BEGIN
  open c1;
  for i in 1..5 loop
    fetch c1 into my_name,my_id,my_salary;
    exit when c1%NOTFOUND; 
    insert into temp values(my_salary,my_id,my_name);
    commit;
  end loop;
  close c1;
END;  
    
-------------------------------------------------------------------------
--Sample 3. Scoping
-------------------------------------------------------------------------
/*The following example illustrates block structure and scope rules. 
An outer block declares two variables named x and counter and loops four times. 
Inside this loop is a sub-block that also declares a variable named x. 
The values inserted into the temp table show that the two x's are indeed different.*/

DECLARE 
  x number :=0;
  counter number :=0;
BEGIN
 -- dbms_output.enable;
  for i in 1..4 loop
    x := x + 100;
    counter := counter + 1;
    insert into temp values (x,counter,'in OUTER loop');
    DBMS_OUTPUT.put_line(a => 'in OUTER loop' );
    DECLARE
      y number := 0;
    BEGIN
      for i in 1..4 loop
        y := y + 1;
        counter := counter + 1;
        insert into temp values(y,counter,'inner loop');
        DBMS_OUTPUT.put_line(a => 'in inner loop' );
      end loop;
    END;
  end loop;
  commit;
END;        

-- without 2 blocks
DECLARE 
  x number :=0;
  y number := 0;
  counter number :=0;
BEGIN
 -- dbms_output.enable;
  for i in 1..4 loop
    x := x + 100;
    counter := counter + 1;
    insert into temp values (x,counter,'in OUTER loop');
    DBMS_OUTPUT.put_line(a => 'in OUTER loop' );
    for i in 1..4 loop
      y := y + 1;
      counter := counter + 1;
      insert into temp values(y,counter,'inner loop');
      DBMS_OUTPUT.put_line(a => 'in inner loop' );
    end loop;
  end loop;
  commit;
END;                  

-------------------------------------------------------------------------
--Sample 4. Batch Transaction Processing
-------------------------------------------------------------------------

CREATE TABLE accounts (
       account_id number,
       balance number
       );
       
CREATE TABLE action (
       account_id number,
       oper_type varchar(10),
       new_value number,
       status varchar2(500),
       time_tag timestamp
       );

drop table accounts;
drop table action;     
  
insert into accounts(account_id, balance) values (1,1000);
insert into accounts(account_id, balance) values (2,2000);
insert into accounts(account_id, balance) values (3,1500);
insert into accounts(account_id, balance) values (4,6500);
insert into accounts(account_id, balance) values (5,500);

select * from accounts;

insert into action(account_id,oper_type,new_value,time_tag) values (3,'u',599,'181188');                
insert into action(account_id,oper_type,new_value,time_tag) values (1,'i',399,'181188');
insert into action(account_id,oper_type,new_value,time_tag) values (5,'d',null,'181188');
insert into action(account_id,oper_type,new_value,time_tag) values (10,'x',null,'181188');                 
insert into action(account_id,oper_type,new_value,time_tag) values (9,'d',null,'181188');                   
insert into action(account_id,oper_type,new_value,time_tag) values (7,'u',1599,'181188');                   
insert into action(account_id,oper_type,new_value,time_tag) values (6,'i',2099,'181188');                                   
                   
select * from action order by time_tag;   

DECLARE
   CURSOR c1 IS
      SELECT account_id, oper_type, new_value FROM action
      ORDER BY time_tag
      FOR UPDATE OF status;
BEGIN
  
   FOR acct IN c1 LOOP  -- process each row one at a time

   acct.oper_type := upper(acct.oper_type);

   /*----------------------------------------*/
   /* Process an UPDATE.  If the account to  */
   /* be updated doesn't exist, create a new */
   /* account.                               */
   /*----------------------------------------*/
   IF acct.oper_type = 'U' THEN
      UPDATE accounts SET balance = acct.new_value
         WHERE account_id = acct.account_id;

      IF SQL%NOTFOUND THEN  -- account didn't exist. Create it.
         INSERT INTO accounts
            VALUES (acct.account_id, acct.new_value);
         UPDATE action SET status =
            'Update: ID not found. Value inserted.'
            WHERE CURRENT OF c1;
      ELSE
         UPDATE action SET status = 'Update: Success.'
            WHERE CURRENT OF c1;
      END IF;

   /*--------------------------------------------*/
   /* Process an INSERT.  If the account already */
   /* exists, do an update of the account        */
   /* instead.                                   */
   /*--------------------------------------------*/
   ELSIF acct.oper_type = 'I' THEN
       BEGIN
         INSERT INTO accounts
            VALUES (acct.account_id, acct.new_value);
         UPDATE action set status = 'Insert: Success.'
            WHERE CURRENT OF c1;
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN   -- account already exists
               UPDATE accounts SET balance = acct.new_value
                  WHERE account_id = acct.account_id;
               UPDATE action SET status =
                  'Insert: Acct exists. Updated instead.'
                  WHERE CURRENT OF c1;
       END;
   /*--------------------------------------------*/
   /* Process a DELETE.  If the account doesn't  */
   /* exist, set the status field to say that    */
   /* the account wasn't found.                  */
   /*--------------------------------------------*/
   ELSIF acct.oper_type = 'D' THEN
      DELETE FROM accounts
         WHERE account_id = acct.account_id;

      IF SQL%NOTFOUND THEN   -- account didn't exist.
         UPDATE action SET status = 'Delete: ID not found.'
            WHERE CURRENT OF c1;
      ELSE
         UPDATE action SET status = 'Delete: Success.'
            WHERE CURRENT OF c1;
      END IF;
  
   /*--------------------------------------------*/
   /* The requested operation is invalid.        */
   /*--------------------------------------------*/
   ELSE  -- oper_type is invalid
      UPDATE action SET status =
         'Invalid operation. No action taken.'
         WHERE CURRENT OF c1;

   END IF;

   END LOOP;
   COMMIT;
   

END;

select * from action;
SELECT * FROM accounts ;

SELECT * FROM accounts ORDER BY account_id;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
select * from emp order by salary desc;

declare 
       sal emp.salary%TYPE;
begin
  insert into emp values ('TOM LEE',0006,10000);
  begin
    update emp set salary = salary + 5000 
           where id = 0006;
    select salary into sal 
           from emp
           where id = 0006;             
  end;   
   dbms_output.put_line('Salary increase to : ' ||sal);
  /* delete from emp 
          where id = 0006;*/
   commit;
end;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------               
DECLARE

CURSOR csr_ac (p_name VARCHAR2) IS
SELECT name ,id, salary
FROM emp
WHERE name LIKE '%p_name%';

BEGIN

FOR rec_ac IN csr_ac ('BAKOLAS') LOOP
   DBMS_OUTPUT.PUT_LINE(rec_ac.id || ' ' ||rec_ac.name || ' '||rec_ac.salary); 
END LOOP ;

END;     

DECLARE

CURSOR csr_ac (p_name VARCHAR2) IS
SELECT id, name, salary
FROM emp
WHERE name LIKE '%p_name%';

v_a emp.id%TYPE;

v_b emp.name%TYPE;

v_c emp.salary%TYPE;

BEGIN 
    OPEN csr_ac ('BAKOLAS');
    LOOP 
        FETCH csr_ac INTO v_a, v_b, v_c;
        EXIT WHEN csr_ac%NOTFOUND;                       

        DBMS_OUTPUT.PUT_LINE(v_a || ' ' || v_b || ' '||v_c); 

    END LOOP;
    CLOSE csr_ac;
END; 


--------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--a simple procedure
create procedure hire1_employee(eid number,name varchar2) is
  begin
    insert into emp values (name,eid,1000);
 end hire1_employee;
 
 drop procedure hire1_employee;
 
 select * from emp order by salary desc;
 
execute HIRE1_EMPLOYEE(2123,'DOKOS');
 
-- a simple function
function salary_ok(salary real,title real) return boolean is
  min_sal real;
  max_sal real;
  begin
    select losal,hisal into min_sal,max_sal
    from salaries
    where job = title;
    return(salary >= min_sal) and (salary <= max_sal);
end salary_ok;    

--simple package
--package specification
create or replace package test as 
       type list is varray(25) of number(3);
       procedure hire_employee(emp_id number,name varchar2);
       procedure fire_employee(emp_id number);
       procedure raise_salary(emp_id number, amount real);
end test;       
--package body
create or replace package body test as
       procedure hire_employee(emp_id number ,name varchar2) is
         begin
           insert into emp values (name, emp_id,1000); 
         end hire_employee; 
       
       procedure fire_employee(emp_id number)is 
         begin
           delete from emp where id = emp_id;
         end fire_employee;
       
       procedure raise_salary(emp_id number,amount real)is
         begin
           update emp set salary = salary + amount
                  where id = emp_id;
           dbms_output.put_line('increase salary : ', || to_char(amount));
         end raise_salary;
end test; 
             
EXECUTE hire_employee(1221,'DOKOS');
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

DECLARE
   type namesarray IS VARRAY(5) OF VARCHAR2(10);
   type grades IS VARRAY(5) OF INTEGER;
   names namesarray;
   marks grades;
   total integer;
BEGIN
   names := namesarray('Kavita', 'Pritam', 'Ayan', 'Rishav', 'Aziz');
   marks:= grades(98, 97, 78, 87, 92);
   total := names.count;
   dbms_output.put_line('Total '|| total || ' Students');
   FOR i in 1 .. total LOOP
      dbms_output.put_line('Student: ' || names(i) || '
      Marks: ' || marks(i));
   END LOOP;
END;    

--------------------------------------------------------------------------------------------------------------------------









































