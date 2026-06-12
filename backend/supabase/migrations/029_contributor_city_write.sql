-- Allow contributors to create cities (pending admin approval)
UPDATE acl_permissions SET can_write = true
WHERE role = 'contributor' AND resource = 'cities';
