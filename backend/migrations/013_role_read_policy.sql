-- Sanad role-routing prerequisite 013
-- Apply after 011-012. Allows a signed-in user to read only their active roles.

DROP POLICY IF EXISTS "users read own active roles" ON public.user_roles;

CREATE POLICY "users read own active roles"
ON public.user_roles
FOR SELECT
TO authenticated
USING (user_id = auth.uid());
