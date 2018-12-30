drop table adf_cascading_lookup_asst;
drop table adf_cascading_lookup_rel;
drop table adf_lookups;
drop table adf_lookup_types;
create table adf_lookup_types
(
   lookup_type varchar2(30) not null,
   meaning     varchar2(80),
   description varchar2(240),
   constraint adf_lookup_types_pk primary key (lookup_type)
);
create table adf_cascading_lookup_rel
(
  id number(18),
  parent_lookup_type varchar2(30) not null,
  child_lookup_type varchar2(30) not null,
  constraint c_lookup_rel_pk primary key (id)
);
create table adf_cascading_lookup_asst
(
  relationship_id    number(18),
  parent_lookup_code varchar2(30),
  child_lookup_code  varchar2(30),
  constraint c_lookup_ast_pk primary key (relationship_id,parent_lookup_code,child_lookup_code),
  constraint lookup_rel_id foreign key (relationship_id) references adf_cascading_lookup_rel
);
create table adf_lookups
(
   lookup_type varchar2(30) not null,
   lookup_code varchar2(80) not null,
   meaning     varchar2(80),
   display_sequence number(18),
   description varchar2(240),
   enabled_flag varchar2(1) default 'Y',
   start_date_active date,
   end_date_active date,
   constraint adf_lookups_pk primary key (lookup_type,lookup_code),
   constraint lookup_type_fk foreign key (lookup_type) references adf_lookup_types
);
insert into adf_lookup_types values ('YES_NO','Yes or No values',null);
insert into adf_lookup_types values ('TRUE_FALSE','True or False values',null);
insert into adf_lookup_types values ('OPEN_CLOSED','Open or Closed values',null);
insert into adf_lookup_types values ('COLORS','List of colors',null);
insert into adf_lookup_types values ('AUTO_MAKE','List of auto makers',null);
insert into adf_lookup_types values ('AUTO_MODEL','List of auto models',null);
insert into adf_lookup_types values ('FRUIT CODES','List of fruits',null);
insert into adf_lookup_types values ('FAMOUS.AUTHOR.NAMES','List of famous authors',null);


insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('YES_NO','Y','Yes',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('YES_NO','N','No',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('TRUE_FALSE','T','True',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('TRUE_FALSE','F','False',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('OPEN_CLOSED','O','Open',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('OPEN_CLOSED','C','Closed',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('COLORS','RED','Red',1,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('COLORS','GREEN','Green',2,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('COLORS','Blue','Blue',3,null);

insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','VW','Volkswagen',1,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','AU','Audi',2,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','TY','Toyota',3,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','MB','Mercedes-Benz',4,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','BMW','BMW',5,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','POR','Porsche',6,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','AR','Alfa Romeo',7,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','FR','Ferrari',8,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','LAM','Lamborghini',9,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','MAS','Maserati',10,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','VOL','Volvo',11,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','REN','Renault',12,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','AM','Aston Martin',13,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','JAG','Jaguar',14,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','MIN','MINI',15,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','LOT','Lotus',16,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','RR','Rolls-Royce',17,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','CAD','Cadillac',18,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','JP','JEEP',19,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','CHV','Chevrolet',20,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','OLD','Oldsmobile',21,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','BU','Buick',22,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','MAZ','Mazda',23,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','FRD','Ford',24,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','CHR','Chrysler',25,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','DO','Dodge',26,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','LIN','Lincoln',27,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','LEX','Lexus',28,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','HON','Honda',29,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MAKE','NIS','Nissan',30,null);

insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','BTL','New Beetle',6,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','GLF','Golf',5,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','TRN','Touran',8,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','A4','A4',1,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','A5','A5',2,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','A6','A6',3,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','YAR','Yaris',9,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','CAM','Camry',4,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','RAV','RAV4',7,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','SLK350','SLK350 Roadster',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','CL600','CL600 Coupe',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','Z4','Z4',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','944','944',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','CAY','Cayman',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','SPR','Spider',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','TRS','Taurus',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','FUS','Fusion',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','CVC','Civic',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','ELE','Element',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','MAX','Maxima',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','ESC','Escalade',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','CHK','Cherokee',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','GRT','GranTurismo',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','TWN','Town Car',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','CAR','Caravan',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','LB','LeBaron',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','MIA','Miata',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','SKY','Skylark',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','XK','XK',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('AUTO_MODEL','MIN','Mini Paceman',null,null);

insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('FRUIT CODES','A','Apple',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('FRUIT CODES','P','Pear',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('FRUIT CODES','M','Mango',null,null);

insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('FAMOUS.AUTHOR.NAMES','PT','Paul Theroux',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('FAMOUS.AUTHOR.NAMES','EH','Ernest Hemingway',null,null);
insert into adf_lookups(lookup_type,lookup_code,meaning,display_sequence,description)
 values ('FAMOUS.AUTHOR.NAMES','MT','Mark Twain',null,null);

insert into adf_cascading_lookup_rel values (1,'AUTO_MAKE','AUTO_MODEL');
insert into adf_cascading_lookup_asst values (1,'VW','GLF');
insert into adf_cascading_lookup_asst values (1,'VW','BTL');
insert into adf_cascading_lookup_asst values (1,'VW','TRN');
insert into adf_cascading_lookup_asst values (1,'AUD','A4');
insert into adf_cascading_lookup_asst values (1,'AUD','A5');
insert into adf_cascading_lookup_asst values (1,'AUD','A6');
insert into adf_cascading_lookup_asst values (1,'TOY','YAR');
insert into adf_cascading_lookup_asst values (1,'TOY','CAM');
insert into adf_cascading_lookup_asst values (1,'TOY','RAV');

drop synonym alternate_adf_lookups;
drop synonym alternate_adf_lookup_types;

create synonym alternate_adf_lookups for adf_lookups;
create synonym alternate_adf_lookup_types for adf_lookup_types;

commit;
