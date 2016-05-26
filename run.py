#!/usr/bin env python
import download.get as get
import sys


def get_all(after):
  print(after)
  inst = get.GetFields()
  inst.export_fields()
  print("Fields Download")

  inst = get.GetGroups()
  inst.export_groups()
  print("Groups Download")

  inst = get.GetContacts()
  inst.export_contacts(parameters=after['after_contacts'])
  print("Contacts Download")

  inst = get.GetFlows()
  inst.export_flows(parameters=after['after_flows'])
  print("Flows Download")

  inst = get.GetMessages()
  inst.export_messages(parameters=after['after_messages'])
  print("Messages Download")

  inst = get.ExportRuns()
  inst.export_runs(parameters=after['after_runs'])
  print("Runs Download")


after = {}
if len(sys.argv) > 4:
  after['after_runs'] = {'after': (sys.argv[4]).split('=')[1]}
  if (sys.argv[4]).split('=')[1] == '':
    after['after_runs'] = {}
if len(sys.argv) > 3:
  after['after_flows'] = {'after': sys.argv[3].split('=')[1]}
  if sys.argv[3].split('=')[1] == '':
    after['after_flows'] = {}
if len(sys.argv) > 2:
  after['after_messages'] = {'after': sys.argv[2].split('=')[1]}
  if sys.argv[2].split('=')[1] == '':
    after['after_messages'] = {}
if len(sys.argv) > 1:
  after['after_contacts'] = {'after': sys.argv[1].split('=')[1]}
  if sys.argv[1].split('=')[1] == '':
    after['after_contacts'] = {}

print(sys.argv)
get_all(after=after)
