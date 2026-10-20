-- Run ONCE after the owner has signed up on the website or app.
-- Replace the email with the owner's login email.
update public.profiles
set role = 'admin'
where email = 'owner@example.com';
