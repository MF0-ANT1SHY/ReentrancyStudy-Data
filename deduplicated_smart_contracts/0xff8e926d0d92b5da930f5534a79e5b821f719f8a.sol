/**
 *Submitted for verification at Etherscan.io on 2020-03-27
*/

pragma solidity 0.5.16; /*


___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



 �������������[ �����[�����[     �����[     �����[ �������������[ �������[   �����[    �������[   �������[ �������������[ �������[   �����[���������������[�����[   �����[
 �����X�T�T�����[�����U�����U     �����U     �����U�����X�T�T�T�����[���������[  �����U    ���������[ ���������U�����X�T�T�T�����[���������[  �����U�����X�T�T�T�T�a�^�����[ �����X�a
 �������������X�a�����U�����U     �����U     �����U�����U   �����U�����X�����[ �����U    �����X���������X�����U�����U   �����U�����X�����[ �����U�����������[   �^���������X�a 
 �����X�T�T�����[�����U�����U     �����U     �����U�����U   �����U�����U�^�����[�����U    �����U�^�����X�a�����U�����U   �����U�����U�^�����[�����U�����X�T�T�a    �^�����X�a  
 �������������X�a�����U���������������[���������������[�����U�^�������������X�a�����U �^���������U    �����U �^�T�a �����U�^�������������X�a�����U �^���������U���������������[   �����U   
 �^�T�T�T�T�T�a �^�T�a�^�T�T�T�T�T�T�a�^�T�T�T�T�T�T�a�^�T�a �^�T�T�T�T�T�a �^�T�a  �^�T�T�T�a    �^�T�a     �^�T�a �^�T�T�T�T�T�a �^�T�a  �^�T�T�T�a�^�T�T�T�T�T�T�a   �^�T�a   
                                                                                            


-------------------------------------------------------------------
 Copyright (c) 2020 onwards Billion Money Inc. ( https://billionmoney.live )
-------------------------------------------------------------------
 */



//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {

    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



//*******************************************************************//
//------------------         PAX interface        -------------------//
//*******************************************************************//

 interface paxInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }




//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract billionMoney is owned {

    // Replace below address with main PAX token
    address public paxTokenAddress;
    uint public maxDownLimit = 2;
    uint public levelLifeTime = 15552000;  // =180 days;
    uint public lastIDCount = 0;
    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID
    
    address public specialAddress1;
    address public specialAddress2;


    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    mapping(uint => uint) public priceOfLevel;
    mapping(uint => uint) public distForLevel;
    mapping(uint => uint) public autoPoolDist;
    mapping(uint => uint) public uniLevelDistPart;
    uint256 public totalDivCollection;
    uint public globalDivDistPart = 0.6 ether;
    uint public systemDistPart = 1 ether;
    
    uint public oneMonthDuration = 2592000; // = 30 days
    uint public thisMonthEnd;
    struct divPoolRecord
    {
        uint totalDividendCollection;
        uint totalEligibleCount;
    }
    divPoolRecord[] public divPoolRecords;
    mapping ( address => uint) public eligibleUser; // if val > 0 then user is eligible from this divPoolRecords;
    mapping(uint => mapping ( address => bool)) public dividendReceived; // dividend index => user => true/false

    struct autoPool
    {
        uint userID;
        uint autoPoolParent;
    }
    mapping(uint => autoPool[]) public autoPoolLevel;  // users lavel records under auto pool scheme
    mapping(address => mapping(uint => uint)) public autoPoolIndex; //to find index of user inside auto pool
    uint[10] public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 
    uint[10] public nextMemberFillBox;   // 3 downline to each, so which downline need to fill in

    uint[10][10] public autoPoolSubDist;

    

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable) public userAddressByID;

    mapping(address => uint256) public totalGainInMainNetwork; //Main lavel income system income will go here with owner mapping
    mapping(address => uint256) public totalGainInUniLevel; 
    mapping(address => uint256) public totalGainInAutoPool;
    mapping(address => uint256) public netTotalUserWithdrawable;  //Dividend is not included in it


    event regLevelEv(address indexed _userWallet, uint indexed _userID, uint indexed _referrerID, uint _time, address _refererWallet, uint _originalReferrer);
    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event payDividendEv(uint timeNow,uint payAmount,address paitTo);
    event updateAutoPoolEv(uint timeNow,uint autoPoolLevelIndex,uint userIndexInAutoPool, address user);
    event autoPoolPayEv(uint timeNow,address paidTo,uint paidForLevel, uint paidAmount, address paidAgainst);
    event paidForUniLevelEv(uint timeNow,address PaitTo,uint Amount);
    
    constructor(address payable ownerAddress, address payable ID1address, address _specialAddress1, address _specialAddress2) public {
        owner = ownerAddress;
        specialAddress1 = _specialAddress1;
        specialAddress2 = _specialAddress2;
        emit OwnershipTransferred(address(0), owner);
        address payable ownerWallet = ID1address;
        priceOfLevel[1] = 20 ether;
        priceOfLevel[2] = 20 ether;
        priceOfLevel[3] = 40 ether;
        priceOfLevel[4] = 140 ether;
        priceOfLevel[5] = 600 ether;
        priceOfLevel[6] = 5000 ether;
        priceOfLevel[7] = 5500 ether;
        priceOfLevel[8] = 10000 ether;
        priceOfLevel[9] = 20000 ether;
        priceOfLevel[10] = 40000 ether;

        distForLevel[1] = 10 ether;
        distForLevel[2] = 15 ether;
        distForLevel[3] = 30 ether;
        distForLevel[4] = 120 ether;
        distForLevel[5] = 500 ether;
        distForLevel[6] = 4700 ether;
        distForLevel[7] = 5000 ether;
        distForLevel[8] = 9000 ether;
        distForLevel[9] = 18000 ether;
        distForLevel[10] = 35000 ether;

        autoPoolDist[1] = 4 ether;
        autoPoolDist[2] = 5 ether;
        autoPoolDist[3] = 10 ether;
        autoPoolDist[4] = 20 ether;
        autoPoolDist[5] = 100 ether;
        autoPoolDist[6] = 300 ether;
        autoPoolDist[7] = 500 ether;
        autoPoolDist[8] = 1000 ether;
        autoPoolDist[9] = 2000 ether;
        autoPoolDist[10] = 5000 ether;        

        uniLevelDistPart[1] = 1 ether;
        uniLevelDistPart[2] = 0.6 ether;
        uniLevelDistPart[3] = 0.4 ether;

        for (uint i = 4 ; i < 11; i++)
        {
           uniLevelDistPart[i] =  0.2 ether;
        } 

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 0,
            referral: new address[](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 10; i++) {
            userInfos[ownerWallet].levelExpired[i] = 99999999999;
            emit paidForLevelEv(address(0), ownerWallet, i, distForLevel[i], now);
        }

        autoPool memory temp;
        for (uint i = 11 ; i < 21; i++)
        {
           uniLevelDistPart[i] =  0.1 ether;
           uint a = i-11;
           temp.userID = lastIDCount;  
           autoPoolLevel[a].push(temp);
         
           autoPoolIndex[ownerWallet][a] = 0;
           uint distPart = autoPoolDist[a+1];
           autoPoolSubDist[a][0] = distPart * 1250 / 10000;
           autoPoolSubDist[a][1] = distPart * 1250 / 10000;
           autoPoolSubDist[a][2] = distPart * 1000 / 10000;
           autoPoolSubDist[a][3] = distPart * 750 / 10000;
           autoPoolSubDist[a][4] = distPart * 750 / 10000;
           autoPoolSubDist[a][5] = distPart * 750 / 10000;
           autoPoolSubDist[a][6] = distPart * 750 / 10000;
           autoPoolSubDist[a][7] = distPart * 1000 / 10000;
           autoPoolSubDist[a][8] = distPart * 1250 / 10000;                                                                             
           autoPoolSubDist[a][9] = distPart * 1250 / 10000;
        } 

        startNextMonth();
        eligibleUser[ownerWallet] = 1;
        emit regLevelEv(ownerWallet, 1, 0, now, address(this), 0);

    }

    function () payable external {
        regUser(defaultRefID);
    }

    function regUser(uint _referrerID) public returns(bool) 
    {
        //this saves gas while using this multiple times
        address msgSender = msg.sender; 
        uint originalReferrer = _referrerID;

        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        uint fct = 1;
        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;


        //transferring PAX tokens from smart user to smart contract for level 1
        if(!(msgSender==specialAddress1 || msgSender == specialAddress2)){
            require( paxInterface(paxTokenAddress).transferFrom(msgSender, address(this), priceOfLevel[1]),"token transfer failed");
        }
        else
        {
            fct = 0;
        }
        
        //update variables
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            referral: new address[](0)
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msgSender].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_referrerID]].referral.push(msgSender);

        totalGainInMainNetwork[owner] += systemDistPart * fct;
        netTotalUserWithdrawable[owner] += systemDistPart * fct;

        if(thisMonthEnd < now) startNextMonth();

        uint lastDivPoolIndex = divPoolRecords.length -1;
        divPoolRecords[lastDivPoolIndex].totalDividendCollection += globalDivDistPart * fct;
        totalDivCollection += globalDivDistPart * fct;

        address usr = userAddressByID[_referrerID];
        if(eligibleUser[usr] == 0)
        {
            if(userInfos[usr].referral.length > 9)
            {
                eligibleUser[usr] = lastDivPoolIndex;
                divPoolRecords[lastDivPoolIndex + 1].totalEligibleCount++;
            }
        }

        require(payForLevel(1, msgSender,fct),"pay for level fail");
        emit regLevelEv(msgSender, lastIDCount, _referrerID, now,userAddressByID[_referrerID], originalReferrer );
        emit levelBuyEv(msgSender, 1, priceOfLevel[1] * fct, now);
        require(updateNPayAutoPool(1,msgSender,fct),"auto pool update fail");
        return true;
    }

    function viewCurrentMonthDividend() public view returns(uint256 amount, uint256 indexCount)
    {
        uint256 length = divPoolRecords.length;
        return (divPoolRecords[length-1].totalDividendCollection,length);
    }

    function buyLevel(uint _level) public returns(bool){
        
        //this saves gas while using this multiple times
        address msgSender = msg.sender;   
        
        
        //checking conditions
        require(userInfos[msgSender].joined, 'User not exist'); 
        uint fct=1;
        require(_level >= 1 && _level <= 10, 'Incorrect level');
        
        //transfer tokens
        if(!(msgSender==specialAddress1 || msgSender == specialAddress2)){
            require( paxInterface(paxTokenAddress).transferFrom(msgSender, address(this), priceOfLevel[_level]),"token transfer failed");
        }
        else
        {
            fct = 0;
        }
        
        
        //updating variables
        if(_level == 1) {
            userInfos[msgSender].levelExpired[1] += levelLifeTime;
        }
        else {
            for(uint l =_level - 1; l > 0; l--) require(userInfos[msgSender].levelExpired[l] >= now, 'Buy the previous level');

            if(userInfos[msgSender].levelExpired[_level] == 0) userInfos[msgSender].levelExpired[_level] = now + levelLifeTime;
            else userInfos[msgSender].levelExpired[_level] += levelLifeTime;
        }

        require(payForLevel(_level, msgSender,fct),"pay for level fail");
        emit levelBuyEv(msgSender, _level, priceOfLevel[_level] * fct, now);
        require(updateNPayAutoPool(_level,msgSender,fct),"auto pool update fail");
        return true;
    }
    

    function payForLevel(uint _level, address _user,uint fct) internal returns (bool){
        address referer;
        address referer1;
        address referer2;
        address referer3;
        address referer4;

        if(_level == 1 || _level == 6) {
            referer = userAddressByID[userInfos[_user].referrerID];
            payForUniLevel(userInfos[_user].referrerID,fct);
            totalGainInMainNetwork[owner] += systemDistPart * fct;
            netTotalUserWithdrawable[owner] += systemDistPart * fct;
        }
        else if(_level == 2 || _level == 7) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer = userAddressByID[userInfos[referer1].referrerID];
        }
        else if(_level == 3 || _level == 8) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer = userAddressByID[userInfos[referer2].referrerID];
        }
        else if(_level == 4 || _level == 9) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer3 = userAddressByID[userInfos[referer2].referrerID];
            referer = userAddressByID[userInfos[referer3].referrerID];
        }
        else if(_level == 5 || _level == 10) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer3 = userAddressByID[userInfos[referer2].referrerID];
            referer4 = userAddressByID[userInfos[referer3].referrerID];
            referer = userAddressByID[userInfos[referer4].referrerID];
        }


        if(!userInfos[referer].joined) referer = userAddressByID[defaultRefID];

       
        if(userInfos[referer].levelExpired[_level] >= now) {
            totalGainInMainNetwork[referer] += distForLevel[_level] * fct;
            netTotalUserWithdrawable[referer] += distForLevel[_level] * fct;
            emit paidForLevelEv(referer, msg.sender, _level, distForLevel[_level] * fct, now);

        }
        else{

            emit lostForLevelEv(referer, msg.sender, _level, distForLevel[_level] * fct, now);
            payForLevel(_level, referer,fct);

        }
        return true;

    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(userInfos[_user].referral.length < maxDownLimit) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(userInfos[referrals[i]].referral.length == maxDownLimit) {
                if(i < 62) {
                    referrals[(i+1)*2] = userInfos[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = userInfos[referrals[i]].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }

    function payForUniLevel(uint _referrerID, uint fct) internal returns(bool)
    {
        uint256 endID = 21;
        for (uint i = 0 ; i < endID; i++)
        {
            address usr = userAddressByID[_referrerID];
            _referrerID = userInfos[usr].referrerID;
            if(usr == address(0)) usr = userAddressByID[defaultRefID];
            uint Amount = uniLevelDistPart[i + 1 ]  * fct;
            totalGainInUniLevel[usr] += Amount;
            netTotalUserWithdrawable[usr] += Amount;
            emit paidForUniLevelEv(now,usr, Amount);
        }
        return true;
    }

    event withdrawMyGainEv(uint timeNow,address caller,uint totalAmount);
    function withdrawMyDividendNAll() public returns(uint)
    {
        address payable caller = msg.sender;
        require(userInfos[caller].joined, 'User not exist');
        uint from = eligibleUser[caller];
        uint totalAmount;
        if(from > 0)
        {
            from --;
            uint lastDivPoolIndex = divPoolRecords.length;
            if( lastDivPoolIndex > 1 )
            {
                lastDivPoolIndex = lastDivPoolIndex -2;

                for(uint i=0;i<150;i++)
                {
                    if(lastDivPoolIndex < i) break;
                    uint curIndex = lastDivPoolIndex - i;
                    if( curIndex >= from && !dividendReceived[curIndex][caller] )
                    {
                        totalAmount +=  ( divPoolRecords[curIndex].totalDividendCollection * 10000000000 /  divPoolRecords[curIndex].totalEligibleCount ) / 10000000000;
                        dividendReceived[curIndex][caller] = true;
                    }

                }
            }
        }
        if(totalAmount > 0)
        {
            totalDivCollection -= totalAmount;
            emit payDividendEv(now, totalAmount, caller);
        }
        totalAmount = totalAmount + netTotalUserWithdrawable[caller];
        netTotalUserWithdrawable[caller] = 0;
        totalGainInAutoPool[caller] = 0;
        totalGainInMainNetwork[caller] = 0;
        totalGainInUniLevel[caller] = 0;
        require(paxInterface(paxTokenAddress).transfer(msg.sender, totalAmount),"token transfer failed");
        emit withdrawMyGainEv(now, caller, totalAmount);
        
    }

    function viewMyDividendPotential(address user) public view returns(uint256 totalDivPotential, uint256 lastUnPaidIndex)
    {
        if (eligibleUser[user] > 0 )
        {
            uint256 i;
            uint256 lastIndex = divPoolRecords.length -1;
            for(i=1;i<50;i++)
            {
                lastUnPaidIndex = lastIndex - i;
                if(dividendReceived[lastUnPaidIndex][user] == true) break;
                totalDivPotential = totalDivPotential + ( divPoolRecords[lastUnPaidIndex].totalDividendCollection * 10000000000 /  divPoolRecords[lastUnPaidIndex].totalEligibleCount);               
            }
            return (totalDivPotential, lastUnPaidIndex + 1);
        }
        return (0,0);
    }

    function viewTimestampSinceJoined(address usr) public view returns(uint256[10] memory timeSinceJoined )
    {
        if(userInfos[usr].joined)
        {
            for(uint256 i=0;i<10;i++)
            {
                uint256 t = userInfos[usr].levelExpired[i+1];
                if(t>now)
                {
                    timeSinceJoined[i] = (t-now);
                }
            }
        }
        return timeSinceJoined;
    }

    
    
    function divPoolAllLevel() public view returns (uint256[10] memory divPoolArray)
    {
        for(uint256 i=0;i<10;i++)
        {
            divPoolArray[i] = divPoolRecords[i].totalDividendCollection;
        }
        return divPoolArray;
    }
    

    function startNextMonth() public returns(bool)
    {
        require(thisMonthEnd < now,"month end not reached");
        thisMonthEnd = now + oneMonthDuration;
        divPoolRecord memory temp;
        temp.totalEligibleCount = 1;
        divPoolRecords.push(temp);
        uint lastDivPoolIndex = divPoolRecords.length -1;
        if (lastDivPoolIndex > 0)
        {
            divPoolRecords[lastDivPoolIndex].totalEligibleCount = divPoolRecords[lastDivPoolIndex -1].totalEligibleCount;
        }
        return (true);
    }

    function updateNPayAutoPool(uint _level,address _user, uint fct) internal returns (bool)
    {
        uint a = _level -1;
        uint len = autoPoolLevel[a].length;
        autoPool memory temp;
        temp.userID = userInfos[_user].id;
        temp.autoPoolParent = nextMemberFillIndex[a];       
        autoPoolLevel[a].push(temp);        
        uint idx = nextMemberFillIndex[a];

        address payable usr = userAddressByID[autoPoolLevel[a][idx].userID];
        if(usr == address(0)) usr = userAddressByID[defaultRefID];
        for(uint i=0;i<10;i++)
        {
            uint amount = autoPoolSubDist[a][i]  * fct;
            totalGainInAutoPool[usr] += amount;
            netTotalUserWithdrawable[usr] += amount;
            emit autoPoolPayEv(now, usr,a+1, amount, _user);
            idx = autoPoolLevel[a][idx].autoPoolParent; 
            usr = userAddressByID[autoPoolLevel[a][idx].userID];
            if(usr == address(0)) usr = userAddressByID[defaultRefID];
        }

        if(nextMemberFillBox[a] == 0)
        {
            nextMemberFillBox[a] = 1;
        }   
        else if (nextMemberFillBox[a] == 1)
        {
            nextMemberFillBox[a] = 2;
        }
        else
        {
            nextMemberFillIndex[a]++;
            nextMemberFillBox[a] = 0;
        }
        autoPoolIndex[_user][_level - 1] = len;
        emit updateAutoPoolEv(now, _level, len, _user);
        return true;
    }


    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userInfos[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].levelExpired[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    
    /*======================================
    =            ADMIN FUNCTIONS           =
    ======================================*/
    
    function changePAXaddress(address newPAXaddress) onlyOwner public returns(string memory){
        //if owner makes this 0x0 address, then it will halt all the operation of the contract. This also serves as security feature.
        //so owner can halt it in any problematic situation. Owner can then input correct address to make it all come back to normal.
        paxTokenAddress = newPAXaddress;
        return("PAX address updated successfully");
    }
    
    function changeDefaultRefID(uint newDefaultRefID) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referral ID.
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }





}