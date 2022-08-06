// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    // kita mapping address ke uint256 jadi nanti address a muncul balance
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        // setting ambang minimum USD untuk mendanai saya 
        // contoh setting ke minimal 10$ dan kita convert ke wei
        uint256 minimumUSD = 0;
        // // // sama seperti if dan else require itu if dan jika tidak
        // // // memenuhi maka else itu revert biasanya revertnya itu Error Message
        require(getConversionRate(msg.value) >= minimumUSD, "You need spent more Eth!");

        // setiap fungsi payable pasti masukin/punya value
        // += value yang udah sender ditambah value nilainya masukin ke sender
        // sama kaya mapping lainnya variable[address => uint256]\
        // address = msg.sender , uint = msg.value
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // ETH -> USD conversion rate
    function getPrice() public view returns(uint256){
        // dari kontrak aggregatorv3 kita buat variabel priceFeed
        // dimana isinya adalah contract dan alamat harganya yaitu ETH/USDD dari rinkeby
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        // kenapa disini ada , kosong karena ini bersifat tuple dan yang ingin
        // dipanggil hanya bagian price saja dari fungsi latestRoundData 
        // pada contract AggregatorV3, aslinya ada 5 variable

        // jadi tuple nya punya nilai priceFeed dari latestRoundData
        (,int256 price,,,) = priceFeed.latestRoundData();
        // disini harus memasukan uint256 sebelum parameter yang mau dikembalikan
        // karena sifat aslinya adalah int256 bukan uint256
        return uint256(price * 1000000000);
        // price nya kita kalikan dengan 1 gwei supaya perhitungan enak
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        // kita bagi ke 10 pangkat 18 supaya desimalnya cuma 8 angka dan lebih mudah dibaca
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
    }

    // sebuah fungsi yang bisa digunakan beberapa kali di jika dibutuhkan
    // supaya tidak mengetik lagi.
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // cara memanggil modifier terletak disini
    function withdraw() payable onlyOwner public {
        uint256 amount = address(this).balance;
        (bool sent,) = owner.call{value: amount}("");
        require(sent, "Failed to send Ether");

        // fungsi untuk update data fund setelah withdraw
        // karena tombol withdraw nge wd semua fungsinya dibikin gini

        // fungsi for ini untuk menambah nilai array index dari nilai
        // yang tersimpan di variable funders dengan fungsi funders.push
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex ++){
            // buat variable baru sifatnya address dan nilainya sama dengan array dari funders
            address funder = funders[funderIndex];
            // update nilai funded dari funder menjadi 0
            addressToAmountFunded[funder] = 0;
        }
        // set variable funders ke array baru yang nilainya 0
        funders = new address[](0);
    }
}
