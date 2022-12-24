class abstract Activity {
    DataTime initialTime;
    DataTime finalTime;
    DataTime totalTime; //really? DataTime contains a funciton for calculate the total time
    
    public Activity() {
    }
    
    public void addTime(DataTime time) {

    }
    
    public DataTime getInitialTime() {
    }

    public DataTime getFinalTime() {
        if (totalTime != null) {
            goBack = totalTime;
        }
        else {
            goBack = DataTime.now();
        }
        return goBack;
    }

    public DataTime getTotalTime() {
        // calculate TotalTime throught DataTime function
    }
    
    public void accept() { //¿?

    }
}
