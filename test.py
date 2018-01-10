#!/usr/bin/python
def matrix():
    import random

    a = 5 # dlina
    b = 5 # shurina
    new = [[ random.randint(0,10) for m in range(a)] for z in range(b)]
    print new
    print("------------")

    for row in new:
        print row
    print("------------")

    list = []

    def create_top(matrix):
        if matrix:
            print('top')
            return matrix.pop(0)

    def create_right(matrix):
        if matrix:
            print("right")
            right = []
            for i in range(0, len(matrix)):
                remove = matrix[i].pop()
                right.append(remove)
                #right.append(matrix[i][len(matrix)])
            return right

    def create_bottom(matrix):
        if matrix:
            print("bottom")
            return matrix.pop()[::-1]

    def create_left(matrix):
        if matrix:
            print('left')
            left = []
            for i in range(0, len(matrix)):
                remove = matrix[i].pop(0)
                left.append(remove)
            return left[::-1]



    while len(new) > 1:
        list.append(create_top(new))
        list.append(create_right(new))
        list.append(create_bottom(new))
        list.append(create_left(new))


    print new
    if new:
        list.append(new[0])
    print("------------")
    print list


def test_retry():
    def retry(function):
        def execute():
            for i in range(0,5):
                print("Started")
                function()
                print("Executed")
        return execute()


    @retry
    def test():
        print("HELLO")


    test()



def retry_len_function_is_zero(max_count):
    def before(function):
        def wrapper():
            count = 0
            while len(function()) is 0 and count < max_count:
                print("timeout %s" %count)
                count = count + 1
        return wrapper()
    return before


@retry_len_function_is_zero(max_count=5)
def test():
    test = ""
    return test

test