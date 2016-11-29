# Hyungwon Yang
# ENCS

# This script geneartes HMM topology for AM training.
# Setting different number of states and phone clusters is flexible by this script.
# First input should be silence related phone cluter and 2nd to last should be non-silence phone clusters.
# *** Input set ***
# 1st_phone_cluster_name 1st_phone_cluster_state 2nd_phone_cluster_name 2nd_phone_cluster_state ...
# nth_phone_cluster_name nth_phone_cluster_state


import sys
import re

# The number of input arguments.
arg_num = len(sys.argv) - 1
if arg_num%2 != 0:
    raise ValueError("Each phone cluster should be given with its number of HMM states.")

# Retrieve phone name information.
phone=[]
for ph in sys.argv[1::2]:
    phone.append(ph)

# Retrieve phone stsate information.
state=[]
for st in sys.argv[2::2]:
    state.append(st)

# Drawing topology
print("<Topology>")

# non silence topology
ns_phone_num = len(phone) - 1

for ns in range(ns_phone_num):
    now_phone = phone[ns+1]
    fix_phone = re.sub(":"," ",now_phone)
    print("<TopologyEntry>")
    print("<ForPhones>")
    print(fix_phone)
    print("</ForPhones>")

    for s in range(int(state[ns+1])):
        front_s = s+1
        print("<State> "+str(s)+" <PdfClass> "+str(s)+" <Transition> "+str(s)+" 0.75 <Transition> "+str(front_s)+" 0.25 </State>")
    # Final state (This is not included main states.)
    print("<State> " + state[ns+1] +" </State>")
    print("</TopologyEntry>")

# silence topology

if int(state[0]) > 1:
    transp = 1.0/(int(state[0])-1)
    now_sil = phone[0]
    sil_phone = re.sub(":"," ",now_sil)
    print("<TopologyEntry>")
    print("<ForPhones>")
    print(sil_phone)
    print("</ForPhones>")
    # First line.
    f_line=""
    for start in range(int(state[0])-1):
        f_line+=("<Transition> "+str(start)+" "+str(transp)+" ")
    print("<State> 0 <PdfClass> 0 "+f_line+"</State>")
    # Second line.
    for side in range(1,int(state[0])-1):
        m_line = ""
        for mid in range(1,int(state[0])):
            m_line+=("<Transition> "+str(mid)+" "+str(transp)+" ")
        print("<State> "+str(side)+" <PdfClass> "+str(side)+" "+m_line + "</State>")
    # Final line.
    fs = str(int(state[0])-1)
    print("<State> "+fs+" <PdfClass> "+fs+" <Transition> "+fs+" 0.75 <Transition> "+state[0]+" 0.25 </State>")
    # Last line.
    print("<State> "+ state[0] +" </State>")
    print("</TopologyEntry>")

else:
    now_sil = phone[0]
    sil_phone = re.sub(":", " ", now_sil)
    print("<TopologyEntry>")
    print("<ForPhones>")
    print(sil_phone)
    print("</ForPhones>")
    print("<State> 0 <PdfClass> 0 <Transition> 0 0.75 <Transition> 1 0.25 </State>")
    print("<State> "+state[0]+" </State>")
    print("</TopologyEntry>")

print("</Topology>")
