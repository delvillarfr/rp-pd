##################### Packages #####################
cat("\014")
rm(list=setdiff(ls(), "root"))

library(plyr)
library(dplyr)
library(readstata13)

library(ggplot2)
library(scales)
library(reshape2)
library(ISOweek)
library(DataCombine)


##################### Directory #####################

# Set root to run report_master.py
args <- commandArgs(TRUE)
#root <- args[1]
#root = "C:/Users/Kin/Dropbox/DropboxQFPD/"
root <-"/Users/Ana1/Dropbox/DropboxQFPD"
desktop <-"/Users/Ana1/Desktop/"

here <- paste(root, "/pProcessed/rapidpro/runs", sep="")
runs_path <- paste(root, "/pRaw/rapidpro/runs/runs.csv", sep="")
contacts_path <- paste(root, "/pRaw/rapidpro/contacts/contacts.csv", sep="")
#contacts_path <- paste(root, "/pProcessed/rapidpro/contacts/contacts.csv", sep="")
report_path <- paste(root, "/pRaw/rapidpro/runs/reporteCampoConcentrado_20160610.dta", sep="")

##################### RAW DATA #####################
runs <- read.csv((runs_path), stringsAsFactors = FALSE)

ls(runs)
unique(runs$flow_campaign)
unique(runs$flow_name)

##################### FILTERS RUNS #####################

# Keep those runs that started after december 7, 2015
runs <- filter(runs, created_on >= "2015-12-07T23:59:59.999Z")

# There is a row without a run (maybe remove this after get.py debug)
runs <- filter(runs, !is.na(run))

# Drop all runs in flow ALTA (Ale Rogel & Co. had to do this)
runs <- filter(runs, flow_name != "TelcelConfirm")

# Drop administrators
contacts <- read.csv(contacts_path)
contacts <- contacts %>%
  select(urns_0, uuid) %>%
  rename(contact = uuid)

runs <- merge(runs, contacts, by="contact", all.x=TRUE)
rm(contacts)

runs <- filter(runs, (urns_0 != "tel:+525518800285") &
                 (urns_0 != "tel:+525571852348") &
                 (urns_0 != "tel:+525517692828"))


##################### RUNS VARIABLES #####################

# Recode completion dummy
runs <- mutate(runs, completed = mapvalues(completed, c("True", "False"), c("1", "0")))
runs$completed = as.numeric(runs$completed)

# Extend response type and label to nodes (R is cool! (and free))
## group by step
## sort to get non-missing response-type first within group
## group by group, replace response_type (label) with first val in group
## drop observations with missing label
runs <- runs %>%
  group_by(node) %>%
  arrange(node, desc(response_type)) %>%
  mutate( response_type = first(response_type),
          label = first(label) ) %>%
  ungroup()

# Tag interactive flows
runs <- runs %>%
  group_by(flow_uuid) %>%
  arrange(desc(origin)) %>%
  mutate(flow_interactive = 1*(first(origin) == "values")) %>%
  ungroup()

# Generate "flow contains date variable" dummy
has_date <- runs %>%
  filter(response_type == "f") %>%
  distinct(flow_uuid) %>%
  mutate(flow_has_date = 1) %>%
  select(flow_uuid, flow_has_date)
runs <- runs %>%
  merge(has_date, by="flow_uuid", all.x=TRUE) %>%
  mutate(flow_has_date = ifelse(is.na(flow_has_date), 0, flow_has_date))
print(table(runs$flow_has_date))
rm(has_date)

##################### CONTACT AND CLINIC VARIABLES #####################

# Add dummy for "contact belongs to pregnant/puerperium messages"

belongs_to <- function(df, group) {
  # Adds dummy col to df with 1{belongs to group}
  # df is a data.frame, group is a string
  
  # Create column
  df["belongs"] <- 0
  
  # For all groups, substitute
  df <- within(df, belongs[groups_0==group] <- 1)
  df <- within(df, belongs[groups_1==group] <- 1)
  df <- within(df, belongs[groups_2==group] <- 1)
  df <- within(df, belongs[groups_3==group] <- 1)
  df <- within(df, belongs[groups_4==group] <- 1)
  df <- within(df, belongs[groups_5==group] <- 1)
  df <- within(df, belongs[groups_6==group] <- 1)
  df <- within(df, belongs[groups_7==group] <- 1)
  df <- within(df, belongs[groups_8==group] <- 1)
  df <- within(df, belongs[groups_9==group] <- 1)
  df <- within(df, belongs[groups_10==group] <- 1)
  df <- within(df, belongs[groups_11==group] <- 1)
  
  return(df)
}

#_________
# CONTACTS
#_________
cat("\014")
contacts <- read.csv(contacts_path, stringsAsFactors=FALSE)
contacts <- contacts %>% rename(contact = uuid) %>%
  select(contact, starts_with("groups_"), 
         fields_rp_duedate, 
         fields_rp_deliverydate,
         fields_rp_created_on,
         fields_ext_clues,
         fields_rp_created_on,
         fields_rp_isvocal_decl,
         fields_rp_isaux_decl)

contacts <- contacts %>%
  # "contact in pregnant campaign" dummy  
  belongs_to("PREGNANT") %>%
  mutate(belongs_PREGNANT = ifelse(fields_rp_duedate != "", belongs,0)) %>%
  # "contact in puerperium campaign" dummy
  belongs_to("PUERPERIUM") %>%
  mutate(belongs_PUERPERIUM = ifelse(fields_rp_deliverydate != "", belongs, 0)) %>%
  # "contact with telcel phone" dummy
  belongs_to("ALTATELCEL") %>% 
  mutate(belongs_TELCEL = belongs) %>%
  # "contact of Prospera Digital" dummy
  belongs_to("ALL") %>%
  mutate(belongs_ALL = belongs) %>%
  mutate(belongs_VOCALAUX=ifelse(fields_rp_isvocal_decl==1 | fields_rp_isaux_decl==1, 1, 0)) %>%
  # "date of contact creation"
  mutate(creation_date = substr(fields_rp_created_on, 1, 10) ) %>%
  # Select vars and renaming clues
  select(contact,
         belongs_PREGNANT,
         belongs_PUERPERIUM, 
         belongs_TELCEL,
         belongs_ALL,
         belongs_VOCALAUX,
         creation_date,
         fields_ext_clues,
         fields_rp_duedate, 
         fields_rp_deliverydate,
         fields_rp_created_on) %>%
  # "rename fields_ext_clues = clues"
  rename(clues = fields_ext_clues)

#Laugh test on contact variables
table(contacts$belongs_PREGNANT)
table(contacts$belongs_PUERPERIUM)
table(contacts$belongs_TELCEL)
table(contacts$belongs_ALL)
contacts$belongs_VOCALAUX[is.na(contacts$belongs_VOCALAUX)] <- 0
table(contacts$belongs_VOCALAUX)

#_________
# CLINICS
#_________

# Hidalgo is missing from reporteCampoConcentrado proxy variable implemented later
clinics <- read.dta13(report_path)
clinics <- select(clinics, clues, cl_treatmentarm, cl_ent_nombre_clcat)

#_________
# MERGE contacts-clinics
#_________

contacts <- merge(contacts, clinics, on="clues", all.x=TRUE)

# Creation of variable state and proxy for Hidalgo
#Hidalgo: 8-Dic-15 a 18-Dic-15
hidalgo_contacts <- select(contacts, creation_date, contact)
hidalgo_contacts$creation_date <- strptime(hidalgo_contacts$creation_date, format="%Y-%m-%d")
hidalgo_contacts <- mutate(hidalgo_contacts, 
                           hidalgo=ifelse(creation_date >= "2015-12-07" & creation_date<="2015-12-18","HIDALGO","") ) 
hidalgo_contacts$creation_date <- NULL
# Very careful with the NAs associated to not having creation_date
hidalgo_contacts$hidalgo[is.na(hidalgo_contacts$hidalgo)] <- ""
hidalgo_contacts <- select(hidalgo_contacts, hidalgo, contact)

table(hidalgo_contacts$hidalgo)

# Creation of state variable
contacts <- merge(contacts, hidalgo_contacts, by="contact", all.x=TRUE)
contacts <- mutate(contacts, estado=paste(hidalgo, cl_ent_nombre_clcat, sep="")) 
contacts$estado[contacts$estado=="NA"] <- "FALTA"
contacts$estado[contacts$estado=="HIDALGONA"] <- "HIDALGO"

# Laugh test for estado
table(contacts$estado)
ls(contacts)

# My contacts, pending check of the previous contacts data base
write.csv(contacts, paste(desktop, "/contacts.csv", sep=""))

#_________
# MERGE runs-contacts
#_________

runs <- merge(runs, contacts, by="contact", all.x=TRUE)

##################### FLOW VARIABLES (CAMPAIGNS) #####################

# Tag steps that require user input
# (and tag those that actually got that input)
runs <- runs %>%
  mutate(step_input_ok = (origin == "values") & (!is.na(text)),
         step_input = (step_input_ok == 1) | is.na(step_time))

# Tag flows by campaign
flows <- runs %>%
  select(flow_uuid,
         flow_name) %>%
  distinct(flow_uuid) %>%
  arrange(flow_name)

flows["flow_campaign"] <- ""

## Concerns
for (i in 1:18) {
  flow <- paste("concerns", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "Concerns")
}
## Incentives
flows <- within(flows, flow_campaign[flow_name == "incentivesInform"] <- "Incentives")
for (i in c(1:5, "F1")) {
  flow <- paste("incentivesCollect", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "Incentives")
}
## Labor
for (i in 1:25) {
  flow <- paste("labor_prep", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "Labor")
}
for (i in 1:6) {
  flow <- paste("labor_milk", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "Labor")
}
for (i in c(1:4, "_init", "_pick")) {
  flow <- paste("labor_getDate", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "Labor")
}
flows <- within(flows, flow_campaign[flow_name == "labor_toPuerperium"] <- "Labor")
## Planning
for (i in 1:7) {
  flow <- paste("prePiloto_planning", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "Planning")
}
## Preventative
for (i in 1:15) {
  flow <- paste("prevent", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "Preventative")
}
## BABIES
for (w in 1:13) {
  for (i in 1:25) {
    flow <- paste("week", as.character(w), ".", as.character(i), sep="")
    flows <- within(flows, flow_campaign[flow_name == flow] <- "Babies")
  }
}
for (v in 1:4) {
  for (i in 1:2) {
    flow <- paste("checkup", as.character(v), ".", as.character(i), sep="")
    flows <- within(flows, flow_campaign[flow_name == flow] <- "Babies")
  }
}
for (w in 1:13) {
  for (i in 1:38) {
    flow <- paste("week", as.character(w), ".e", as.character(i), sep="")
    flows <- within(flows, flow_campaign[flow_name == flow] <- "Babies")
  }
}
## Puerperium
flows <- within(flows, flow_campaign[flow_name == "puerp_0_1" | flow_name=="puerp_0_2"] <- "Puerperium")
for (i in 1:11) {
  flow <- paste("puerp", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "Puerperium")
}
## BABIES3_6
for (w in 14:26) {
  for (i in 1:5) {
    flow <- paste("week", as.character(w), ".", as.character(i), sep="")
    flows <- within(flows, flow_campaign[flow_name == flow] <- "Babies3_6")
  }
}
## Reminders
for (v in 1:5) {
  for (i in 1:3) {
    flow <- paste("reminders", as.character(v), ".", as.character(i), sep="")
    flows <- within(flows, flow_campaign[flow_name == flow] <- "Reminders")  
  }
}
for (v in c("Extra", "Final")) {
  for (i in 1:3) {
    flow <- paste("reminders", as.character(v), as.character(i), sep="")
    flows <- within(flows, flow_campaign[flow_name == flow] <- "Reminders")  
  }
}
## T2_aux
for (i in 1:5) { 
  flow <- paste("t2_aux", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "T2_Aux")
}

## T2_bfs
for (i in 1:2) { 
  flow <- paste("t2_bfs", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "T2_Bfs")
}
## MI ALERTA
flows <- within(flows, flow_campaign[flow_name == "miAlerta"] <- "miAlerta")
## MI Cita
flows <- within(flows, flow_campaign[flow_name == "miCita_bf1"] <- "miCita")
flows <- within(flows, flow_campaign[flow_name == "PrePiloto_miCita"] <- "miCita")
for (i in 1:5) { 
  flow <- paste("miCita_cl2_", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "miCita")
}
for (i in 1:5) { 
  flow <- paste("miCita_bf2_", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "miCita")
}
for (i in 1:5) { 
  flow <- paste("miCita_clFinal_", as.character(i), sep="")
  flows <- within(flows, flow_campaign[flow_name == flow] <- "miCita")
}

table(flows$flow_campaign)
unique(flows$flow_name)

flows <- select(flows, flow_uuid,
                flow_campaign)

runs <- merge(runs, flows, by="flow_uuid", all.x=TRUE)
rm(flows)

##################### OTHER VARIABLES #####################

# Generate categorical var for choice taken in flow auxTexto
# The node in which the decision is made is be0126ac-18fd-421b-8b11-b305ee9bf818
# NOTE: groups of contacts associated to vocales were reformulated on 09/04/2016
# but were already in place since before, circa march 23

runs <- mutate(runs, auxTexto_decision = ifelse((node == "be0126ac-18fd-421b-8b11-b305ee9bf818") &
                                                  (created_on > "2016-03-23T23:59:59.999Z") &
                                                  (completed == 1),
                                                category_spa, ""))
#_________
# INCENTIVES
#_________

# Analyze incentivesCollect flows
incentives <- runs %>%
  filter( (flow_name == "incentivesCollect1") |
            (flow_name == "incentivesCollect2") |
            (flow_name == "incentivesCollect3") |
            (flow_name == "incentivesCollect4") |
            (flow_name == "incentivesCollect5") |
            (flow_name == "incentivesCollectfinal") ) %>%
  select(category_spa, run, label)

# Get questions

# Generate a new df with labels that start with "split.."
# Category_spa equals "other" once (error), before these flows were fully implemented
df_inc_q <- filter(incentives, (substr(label, 1, 5) == "split") & 
                     (category_spa != "Other"))

df_inc_q <- df_inc_q %>%
  # Save question 1 (2) to category_spa if it label equals "split_rand_1_8"
  mutate(inc_q1 = ifelse(label == "split_rand_1_8", strtoi(category_spa), NA),
         inc_q2 = ifelse(label == "split_rand_1_6", strtoi(category_spa), NA)) %>%
  # Keep newly created vars and run
  select(run,
         inc_q1,
         inc_q2) %>%
  # Fill dataset with non-missing vals and set it to run-level
  group_by(run) %>%
  arrange(run, inc_q1) %>%
  mutate(inc_q1 = first(inc_q1)) %>%
  arrange(run, inc_q2) %>%
  mutate(inc_q2 = first(inc_q2)) %>%
  distinct(run)

# Get answers

# Generate a new df with labels that start with "Response.."
# and whose category_spa != "Other"
df_inc_r <- filter(incentives, (substr(label, 1, 8) == "Response") & 
                     (category_spa != "Other"))

df_inc_r <- df_inc_r %>%
  # Retrieve response number from label
  mutate(response_num = strtoi(substr(label, 10, nchar(label)-2))) %>% 
  # Save response 1 (2) to response_num if response_num is less (greater or eq) to 9
  mutate(inc_r1 = ifelse(response_num < 9, strtoi(category_spa), NA),
         inc_r2 = ifelse(response_num > 8, strtoi(category_spa), NA)) %>%
  # Keep newly created vars and run
  select(run,
         inc_r1,
         inc_r2) %>%
  # Fill dataset with non-missing vals and set it to run-level
  group_by(run) %>%
  arrange(run, inc_r1) %>%
  mutate(inc_r1 = first(inc_r1)) %>%
  arrange(run, inc_r2) %>%
  mutate(inc_r2 = first(inc_r2)) %>%
  distinct(run)

# Add questions and answers to incentives
incentives <- select(incentives, run)
incentives <- merge(incentives, df_inc_q, by="run", all.x=TRUE)
incentives <- merge(incentives, df_inc_r, by="run", all.x=TRUE)


# Add everything to runs
runs <- merge(runs, incentives, by="run", all.x=TRUE)
rm(df_inc_r, df_inc_q, incentives)

# Extract answers to concerns questions
#concerns <- filter(runs, )
write.csv(runs, paste(here, "/runs.csv", sep=""))

##################### GRAFICAS #####################

#______________________
# GRAPHS
# messages, rRates, beneficiarias, delivery_dates
#______________________

cat("\014") 
runs<-read.csv(paste(here, "/runs.csv", sep=""), stringsAsFactors=FALSE)

base <- filter(runs, belongs_PUERPERIUM==1 | belongs_PREGNANT==1)
base <- filter(base, estado=="PUEBLA")
base <- arrange(base, created_on)

base<-select(base, created_on, text, contact, belongs_TELCEL,step_input, step_input_ok)
base<-mutate(base, mensajes = (nchar(text)>0)*1,
             date = substr(created_on, 1, 10),
             mensajes_TELCEL = (nchar(text)>0)*1*belongs_TELCEL,
             contact_TELCEL=ifelse(belongs_TELCEL==1,contact,0),
             step_input_TELCEL=step_input*belongs_TELCEL,
             step_input_okTELCEL=step_input_ok*belongs_TELCEL)

base$date<-as.Date(base$date, format="%Y-%m-%d")
base<-mutate(base,week=substr(date2ISOweek(base$date),7,8),
             year=substr(date, 1,4))

View(select(base,date,week,year))

base_graf<-summarize(group_by(base, date),
                     #date=date[1],
                     mensajes=sum(mensajes),
                     beneficiarias=n_distinct(contact),
                     mensajes_p=sum(mensajes)/n_distinct(contact),
                     mensajes_pTELCEL=sum(mensajes_TELCEL)/n_distinct(contact_TELCEL),
                     mensajes_pnoTELCEL=(sum(mensajes)-sum(mensajes_TELCEL))/(n_distinct(contact)-n_distinct(contact_TELCEL)),
                     rRate=sum(step_input_ok)/sum(step_input),
                     rRate_noTELCEL=(sum(step_input_ok)-sum(step_input_okTELCEL))/(sum(step_input)-sum(step_input_TELCEL)),
                     rRate_TELCEL=sum(step_input_okTELCEL)/sum(step_input_TELCEL))

summary(base_graf$rRate)

### rRate graphs ##
base_graf<-arrange(base_graf, date)
base_graf<-mutate(base_graf, rRate_m=(rRate+lag(rRate))/2)

ggplot(base_graf, aes(x=date, y=rRate_m))+
  geom_line(colour="#56B4E9")+scale_x_date(labels = date_format("%m/%Y"))+
  labs(x="Fecha", y="Tasa de Respuesta \n (porcentaje)")

ggsave("/Users/Ana1/Desktop/rRate1.pdf", width=6, height=3.6)

base_graf2<-select(base_graf, date,  rRate_noTELCEL, rRate_TELCEL)
base_graf2<-melt(base_graf2, id=c('date'))

ggplot(filter(base_graf2, date>"2016-05-01"), aes(x=date, y=value, color=variable) )+
  geom_line()+scale_x_date(labels = date_format("%m/%Y"))+
  labs(x="Fecha", y="Tasa de Respuesta \n (porcentaje)")+
  scale_color_manual(values=c("#56B4E9", "firebrick3"),
                     name="Compañía", 
                     breaks=c("rRate_noTELCEL", "rRate_TELCEL"), 
                     labels=c("Otras", "TELCEL"))

ggsave("/Users/Ana1/Desktop/rRate2.pdf", width=6, height=3.6)

### Users Interaction graph ###
base_graf<-arrange(base_graf, date)
base_graf<-mutate(base_graf, beneficiarias_m=(beneficiarias+lag(beneficiarias))/2)

ggplot(base_graf, aes(x=date, y=beneficiarias_m))+
  geom_line(colour="#56B4E9")+scale_x_date(labels = date_format("%m/%Y"))+
  labs(x="Fecha", y="Beneficiarias Interactuando \n (Beneficiarias por día)")

ggsave("/Users/Ana1/Desktop/Beneficiarias.pdf", width=6, height=3.6)

### Daily messages graph ###
base_graf<-arrange(base_graf, date)
base_graf<-mutate(base_graf, mensajes_m=(mensajes+lag(mensajes))/2)

ggplot(base_graf, aes(x=date, y=mensajes_m))+
  geom_line(colour="#56B4E9")+scale_x_date(labels = date_format("%m/%Y"))+
  labs(x="Fecha", y="Mensajes Envíados y Recibidos \n (Mensajes por día)")

ggsave("/Users/Ana1/Desktop/Mensajes.pdf", width=6, height=3.6)




