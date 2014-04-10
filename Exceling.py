__author__ = 'haiyang'
import xlrd
import MySQLdb
import openpyxl
import argparse

# Script arguments parser
parser = argparse.ArgumentParser(
    description='Exceling',
    version="0.1"
)

parser.add_argument('input_file', action="store", help="Path to input file")
parser.add_argument('output_file', action="store", help="Path to output file")
parser.add_argument('--out-csv', action="store_true", help="Output CSV style")

arguments = parser.parse_args()

input_file = arguments.input_file
output_file = arguments.output_file
out_csv = arguments.out_csv

# Connection info to database
conn = MySQLdb.connect(
    host='10.10.81.148',
    user='query',
    db='us_partner',
    port=3306,
    passwd='query'
)
cur = conn.cursor()


class LittleQ:
    """ Make a little queue
    """
    def __init__(self, a_list):
        self.queue = a_list

    def pop(self, num=1):
        dish = []
        for _ in range(num):
            try:
                dish.append(self.queue.pop(0))
            except IndexError:
                break
        return dish


def hand_a(a):
    """
    @param a: The content from a single cell
    @return: According to the SQL you write below, return a list of result get from database
    """

    b = ""
    for e in a:
        b = "%s,\'%s\'" % (b, e[3:])
    b = b.strip(',')
    sql = """SELECT email,userName
          FROM
          PARTNER_USERS LEFT JOIN PARTNER_ORDER ON PARTNER_USERS.identityID = PARTNER_ORDER.partnerUserId
          LEFT JOIN PARTNER_ORDER_OTHER ON PARTNER_ORDER.orderId = PARTNER_ORDER_OTHER.orderId
          WHERE PARTNER_ORDER_OTHER.transactionId LIKE '%s';""" % (b)

    cur.execute(sql)
    res = cur.fetchall()
    return res


def write_book(new_paper, origin_sheet, result):
    """
    @param new_paper: The new excel sheet
    @param origin_sheet: The original excel sheet
    @param result: Result get from method handa
    @return: Nothing
    """
    # new_sheet = paper.add_sheet(origin_sheet.name)
    new_sheet = new_paper.create_sheet()
    new_sheet.title = origin_sheet.name
    print origin_sheet.nrows, len(result)
    # Handle every single row
    for row_num in xrange(origin_sheet.nrows):
        row = origin_sheet.row_values(row_num)
        # According to different excel sheet, this if clause exclude unuseful rows
        # from this process
        if row_num < 7:
            new_sheet.append(row)
        else:
            for one_result in result:
                # "row" is a python list, stand for a single row in the original sheet
                # row[0], row[1], row[3]... mean the first, second, third cell in this row
                # one_result stand for one row of the query result set return from method hand_a(a)
                # this if clause append correspond result to the right row, then write to the new sheet
                if row[2] == one_result[1]:
                    row.append(one_result[0])
                    new_sheet.append(row)
                    result.remove(one_result)
    return

# Main logic
workbook = xlrd.open_workbook(input_file)
paper = openpyxl.Workbook()
paper.remove_sheet(paper.get_active_sheet())

# this "for" clause loop all rows in all sheets in the original excel file
# then uses hand_a() to get all result
# then uses write_book() to write all to an Excel file
for sheet in workbook.sheets():
    if sheet.name:
        all_user_ids = sheet.col_values(2, 1)
        task_queue = LittleQ(all_user_ids)
        res = []
        one_task = task_queue.pop(500)
        while one_task:
            res += hand_a(one_task)
            one_task = task_queue.pop(500)
        if out_csv:
            for a, b in res:
                print "%s,%s" % (a, b)
        else:
            write_book(paper, sheet, res)
    else:
        pass

if out_csv:
    pass
else:
    paper.save(filename=output_file)

# close MySQL connection
conn.close()

