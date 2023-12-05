



import re

# <DeloyGroup Group="idcagent" Host="DS_62_idcagent_1" InstID="1" CustomAttr="zone=3,shadow={AS_HK},idc=asia_hk_11,key=asdhk12adsf31x09as123"/>
def find_matching_zones(file1, file2):

      with open(file1) as f1:
        for zone in f1:
          # print(zone.strip())
          zoneline=zone.strip()
          with open(file2) as f2:
            for line2 in f2:
                  
              patternidc = r'idc='
              matchidc = re.search(patternidc, line2.strip())
              
              if matchidc:
                  # print(line2.strip())
                  orig = line2.strip()
                  # print(orig)
                  if zoneline in orig:
                    print(orig)
                    break
                    


if __name__ == '__main__':
    file1 = 'file1.txt'
    file2 = 'proc_deploy_2.xml'

    find_matching_zones(file1, file2)

