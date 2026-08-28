import math
import sys

def  calculate_metrics(data,factor=1.5):
results = []
for  item  in data:
 val=item*factor
if val > 100:
 results.append(val)
  else:
  results.append(val/2)
return results

def process_string_data(text_list):
# processing strings here
    cleaned = []
    for t in text_list:
        if len(t)>0:
            cleaned.append(t.strip().upper())
        else:
          pass
    return cleaned

def format_output(metrics, strings):
    combined={}
    for i, m in enumerate(metrics):
        if i < len(strings):
            combined[strings[i]]=m
    return combined

def main():
    raw_data=[10, 45, 80, 120, 33]
    raw_text=[" apple ", "banana", "", "cherry  "]
    m = calculate_metrics(raw_data, factor=2.0)
    s = process_string_data(raw_text)
    out = format_output(m, s)
    print("Result:", out)
if __name__ == "__main__":
        main()










