--
-- database_schema_15-16.sql
--
-- Version: $$
--
-- Date:    $Date: 2009-04-23 22:26:59 -0500 (Thu, 23 Apr 2009) $
--
-- Copyright (c) 2002-2009, The DSpace Foundation.  All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are
-- met:
--
-- - Redistributions of source code must retain the above copyright
-- notice, this list of conditions and the following disclaimer.
--
-- - Redistributions in binary form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- - Neither the name of the DSpace Foundation nor the names of its
-- contributors may be used to endorse or promote products derived from
-- this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-- LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
-- A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-- HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
-- BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
-- OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
-- TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
-- USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
-- DAMAGE.

--
-- SQL commands to upgrade the database schema of a live DSpace 1.5 or 1.5.x
-- to the DSpace 1.6 database schema
--
-- DUMP YOUR DATABASE FIRST. DUMP YOUR DATABASE FIRST. DUMP YOUR DATABASE FIRST. DUMP YOUR DATABASE FIRST.
-- DUMP YOUR DATABASE FIRST. DUMP YOUR DATABASE FIRST. DUMP YOUR DATABASE FIRST. DUMP YOUR DATABASE FIRST.
-- DUMP YOUR DATABASE FIRST. DUMP YOUR DATABASE FIRST. DUMP YOUR DATABASE FIRST. DUMP YOUR DATABASE FIRST.

------------------------------------------------------------------
-- New Column for Community Admin - Delegated Admin patch (DS-228)
------------------------------------------------------------------
ALTER TABLE community ADD admin INTEGER REFERENCES epersongroup ( eperson_group_id );
CREATE INDEX community_admin_fk_idx ON Community(admin);

-------------------------------------------------------------------------
-- DS-236 schema changes for Authority Control of Metadata Values
-------------------------------------------------------------------------
ALTER TABLE MetadataValue
  ADD ( authority VARCHAR(100),
        confidence INTEGER DEFAULT -1);

--------------------------------------------------------------------------
-- DS-295 CC License being assigned incorrect Mime Type during submission.
--------------------------------------------------------------------------
UPDATE bitstream SET bitstream_format_id =
   (SELECT bitstream_format_id FROM bitstreamformatregistry WHERE short_description = 'CC License')
   WHERE name = 'license_text' AND source = 'org.dspace.license.CreativeCommons';

UPDATE bitstream SET bitstream_format_id =
   (SELECT bitstream_format_id FROM bitstreamformatregistry WHERE short_description = 'RDF XML')
   WHERE name = 'license_rdf' AND source = 'org.dspace.license.CreativeCommons';

-------------------------------------------------------------------------
-- DS-260 Cleanup of Owning collection column for template item created
-- with the JSPUI after the collection creation
-------------------------------------------------------------------------
UPDATE item SET owning_collection = null WHERE item_id IN
        (SELECT template_item_id FROM collection WHERE template_item_id IS NOT null);

------------------------------------------------------------------------------------------------------
-- You need to remove the already in place constraints to add the deferrable option
-- because the constraints name was generated by your oracle instance you need to discovery it before
-- Just copy and paste the commands printed by these three queries:

-- 1. community2collection
select 'ALTER TABLE '||c1.table_name||' DROP CONSTRAINT '||
 c1.constraint_name||';'  command from user_constraints c1, user_constraints c2
  where c1.constraint_type = 'R' and c1.r_constraint_name = c2.constraint_name
   and c1.table_name like 'COMMUNITY2COLLECTION'
   and c2.table_name LIKE 'COLLECTION';

-- 2. community2community
select 'ALTER TABLE '||c1.table_name||' DROP CONSTRAINT '||
 c1.constraint_name||';'  command from user_constraints c1, user_constraints c2
  where c1.constraint_type = 'R' and c1.r_constraint_name = c2.constraint_name
   and c1.table_name like 'COMMUNITY2COMMUNITY'
   and c2.table_name LIKE 'COMMUNITY';

-- 3. collection2item
select 'ALTER TABLE '||c1.table_name||' DROP CONSTRAINT '||
 c1.constraint_name||';'  command from user_constraints c1, user_constraints c2
  where c1.constraint_type = 'R' and c1.r_constraint_name = c2.constraint_name
   and c1.table_name like 'COLLECTION2ITEM'
   and c2.table_name LIKE 'ITEM';

--
-- e.g.
-- ALTER TABLE community2collection DROP CONSTRAINT THECONSTRAINTNAMETHATYOUHAVEFINDWITHTHE1stQUERY;
-- ALTER TABLE community2community DROP CONSTRAINT THECONSTRAINTNAMETHATYOUHAVEFINDWITHTHE2ndQUERY;
-- ALTER TABLE collection2item DROP CONSTRAINT THECONSTRAINTNAMETHATYOUHAVEFINDWITHTHE3rdQUERY;

-- now recreate them with a know name and deferrable option!
select 'ALTER TABLE community2collection ADD CONSTRAINT comm2coll_collection_fk FOREIGN KEY (collection_id) REFERENCES collection DEFERRABLE;' from dual;
select 'ALTER TABLE community2community ADD CONSTRAINT com2com_child_fk FOREIGN KEY (child_comm_id) REFERENCES community DEFERRABLE;' from dual;
select 'ALTER TABLE collection2item ADD CONSTRAINT coll2item_item_fk FOREIGN KEY (item_id) REFERENCES item DEFERRABLE;' from dual;