import glob
import sys
import xml.etree.ElementTree as ET

def main():
    xml_files = sorted(glob.glob("sim_builds/*/results.xml"))
    if not xml_files:
        print("No test results found in sim_builds/*/results.xml")
        sys.exit(0)

    total_pass = 0
    total_fail = 0
    total_time = 0.0

    print("\n" + "=" * 100)
    print(f"  {'MODULE':<24} {'TESTCASE':<44} {'STATUS':<8} {'TIME (s)':<10} {'SIM TIME (ns)':<12}")
    print("=" * 100)

    for xml_file in xml_files:
        try:
            tree = ET.parse(xml_file)
        except Exception as e:
            print(f"  Warning: could not parse {xml_file}: {e}")
            continue

        for tc in tree.iter("testcase"):
            failed = tc.find("failure") is not None
            status_str = "\033[31mFAIL\033[0m" if failed else "\033[32mPASS\033[0m"
            if failed:
                total_fail += 1
            else:
                total_pass += 1

            mod = tc.attrib.get("classname", "")
            name = tc.attrib.get("name", "")
            try:
                time_s = float(tc.attrib.get("time", "0"))
            except ValueError:
                time_s = 0.0
            total_time += time_s

            sim_time = tc.attrib.get("sim_time_ns", "-")
            if sim_time != "-":
                try:
                    sim_time = f"{float(sim_time):.1f}"
                except ValueError:
                    pass

            print(f"  {mod:<24} {name:<44} {status_str:<17} {time_s:<10.2f} {sim_time:<12}")

    print("=" * 100)
    summary_color = "\033[32m" if total_fail == 0 else "\033[31m"
    total_tests = total_pass + total_fail
    print(f"  TOTAL: {total_tests} tests | {summary_color}{total_pass} passed\033[0m | {total_fail} failed")
    print("=" * 100 + "\n")

    sys.exit(1 if total_fail > 0 else 0)

if __name__ == "__main__":
    main()
