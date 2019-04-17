#ifndef TEST_H
#define TEST_H

template <typename T> 
class Test {
public:
    Test() { data = new T; }
    ~Test() { delete data; }
    
private:
    T *data;
};

#endif