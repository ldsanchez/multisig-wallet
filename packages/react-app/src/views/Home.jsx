import { Divider, Select, Col, Row, List } from "antd";
import React, { useState, useEffect } from "react";

import { Address, Balance, Owners, TransactionListItem, CreateTransaction, Transactions } from "../components";
import { BACKEND_URL } from "../constants";
import CreateMultisigWalletModal from "../components/CreateMultisigWalletModal";
import { useEventListener } from "eth-hooks/events/";
import { useContractReader } from "eth-hooks";
import QR from "qrcode.react";
import nonDeployedABI from "../contracts/hardhat_non_deployed_contracts.json";

const { ethers } = require("ethers");

const { Option } = Select;

export default function MultisigWallet({
  price,
  selectedChainId,
  mainnetProvider,
  localProvider,
  address,
  tx,
  writeContracts,
  readContracts,
  isCreateModalVisible,
  setIsCreateModalVisible,
  DEBUG,
  blockExplorer,
  userSigner,
}) {
  const contractName = "MultisigWallet";
  const contractAddress = readContracts?.MultisigWallet?.address;

  //📟 Listen for broadcast events

  // MultisigWalletFactory Events:
  const ownersMultiSigEvents = useEventListener(readContracts, "MultisigWalletFactory", "Owners", localProvider, 1);
  if (DEBUG) console.log("📟 ownersMultiSigEvents:", ownersMultiSigEvents);

  const [contractNameForEvent, setContractNameForEvent] = useState();
  const [multiSigs, setMultiSigs] = useState([]);
  const [currentMultiSigAddress, setCurrentMultiSigAddress] = useState();

  useEffect(() => {
    if (address) {
      const multiSigsForUser = ownersMultiSigEvents.reduce((filtered, createEvent) => {
        if (createEvent.args.owners.includes(address) && !filtered.includes(createEvent.args.contractAddress)) {
          filtered.push(createEvent.args.contractAddress);
        }

        return filtered;
      }, []);

      if (multiSigsForUser.length > 0) {
        const recentMultiSigAddress = multiSigsForUser[multiSigsForUser.length - 1];
        if (recentMultiSigAddress !== currentMultiSigAddress) setContractNameForEvent(null);
        setCurrentMultiSigAddress(recentMultiSigAddress);
        setMultiSigs(multiSigsForUser);
      }
    }
  }, [ownersMultiSigEvents, address]);

  const [signaturesRequired, setSignaturesRequired] = useState(0);
  const [nonce, setNonce] = useState(0);

  const signaturesRequiredContract = useContractReader(readContracts, contractName, "signaturesRequired");
  const nonceContract = useContractReader(readContracts, contractName, "nonce");
  useEffect(() => {
    setSignaturesRequired(signaturesRequiredContract);
    setNonce(nonceContract);
  }, [signaturesRequiredContract, nonceContract]);

  useEffect(() => {
    async function getContractValues() {
      const signaturesRequired = await readContracts.MultisigWallet.signaturesRequired();
      setSignaturesRequired(signaturesRequired);

      const nonce = await readContracts.MultisigWallet.nonce();
      setNonce(nonce);
    }

    if (currentMultiSigAddress) {
      readContracts.MultisigWallet = new ethers.Contract(
        currentMultiSigAddress,
        nonDeployedABI.MultisigWallet,
        localProvider,
      );
      writeContracts.MultisigWallet = new ethers.Contract(
        currentMultiSigAddress,
        nonDeployedABI.MultisigWallet,
        userSigner,
      );

      setContractNameForEvent("MultisigWallet");
      getContractValues();
    }
  }, [currentMultiSigAddress, localProvider, readContracts, writeContracts]);

  // MultisigWallet Events:
  const allExecuteTransactionEvents = useEventListener(
    currentMultiSigAddress ? readContracts : null,
    contractNameForEvent,
    "ExecuteTransaction",
    localProvider,
    1,
  );
  if (DEBUG) console.log("📟 executeTransactionEvents:", allExecuteTransactionEvents);

  const allOwnerEvents = useEventListener(
    currentMultiSigAddress ? readContracts : null,
    contractNameForEvent,
    "Owner",
    localProvider,
    1,
  );
  if (DEBUG) console.log("📟 ownerEvents:", allOwnerEvents);

  const [ownerEvents, setOwnerEvents] = useState();
  const [executeTransactionEvents, setExecuteTransactionEvents] = useState();

  useEffect(() => {
    setExecuteTransactionEvents(
      allExecuteTransactionEvents.filter(contractEvent => contractEvent.address === currentMultiSigAddress),
    );
    setOwnerEvents(allOwnerEvents.filter(contractEvent => contractEvent.address === currentMultiSigAddress));
  }, [allExecuteTransactionEvents, allOwnerEvents, currentMultiSigAddress]);

  const handleMultiSigChange = value => {
    setContractNameForEvent(null);
    setCurrentMultiSigAddress(value);
  };

  console.log("currentMultiSigAddress:", currentMultiSigAddress);

  const userHasMultiSigs = currentMultiSigAddress ? true : false;

  return (
    <div style={{ padding: 16, margin: "auto", marginTop: 10 }}>
      <Row justify="center">
        <Col>
          <div>
            <CreateMultisigWalletModal
              price={price}
              selectedChainId={selectedChainId}
              mainnetProvider={mainnetProvider}
              address={address}
              tx={tx}
              writeContracts={writeContracts}
              contractName={"MultisigWalletFactory"}
              isCreateModalVisible={isCreateModalVisible}
              setIsCreateModalVisible={setIsCreateModalVisible}
            />
            <Select value={[currentMultiSigAddress]} style={{ width: 400 }} onChange={handleMultiSigChange}>
              {multiSigs.map((address, index) => (
                <Option key={index} value={address}>
                  {address}
                </Option>
              ))}
            </Select>
          </div>
        </Col>
      </Row>
      <Divider />
      <Row justify="space-around">
        <Col lg={6} xs={24}>
          <div>
            <div>
              <h2 style={{ marginTop: 16 }}>Multisig Wallet Balance:</h2>
              <div>
                <Balance
                  address={currentMultiSigAddress ? currentMultiSigAddress : ""}
                  provider={localProvider}
                  dollarMultiplier={price}
                  size={64}
                />
              </div>
              <div>
                <QR
                  value={currentMultiSigAddress ? currentMultiSigAddress.toString() : ""}
                  size="180"
                  level="H"
                  includeMargin
                  renderAs="svg"
                  imageSettings={{ excavate: false }}
                />
              </div>
              <div>
                <Address
                  address={currentMultiSigAddress ? currentMultiSigAddress : ""}
                  ensProvider={mainnetProvider}
                  blockExplorer={blockExplorer}
                  fontSize={32}
                />
              </div>
              <>
                {userHasMultiSigs ? (
                  <div>
                    <Owners
                      ownerEvents={ownerEvents}
                      signaturesRequired={signaturesRequired}
                      mainnetProvider={mainnetProvider}
                      blockExplorer={blockExplorer}
                    />
                  </div>
                ) : (
                  <div></div>
                )}
              </>
            </div>
          </div>
        </Col>
        <Col lg={6} xs={24}>
          <h2 style={{ marginTop: 16 }}>Propose a Transaction:</h2>
          <CreateTransaction
            poolServerUrl={BACKEND_URL}
            contractName={contractName}
            contractAddress={contractAddress}
            mainnetProvider={mainnetProvider}
            localProvider={localProvider}
            price={price}
            tx={tx}
            readContracts={readContracts}
            userSigner={userSigner}
            DEBUG={DEBUG}
            nonce={nonce}
            blockExplorer={blockExplorer}
            signaturesRequired={signaturesRequired}
          />
          <>
            {userHasMultiSigs ? (
              <Transactions
                poolServerUrl={BACKEND_URL}
                contractName={contractName}
                address={address}
                userSigner={userSigner}
                mainnetProvider={mainnetProvider}
                localProvider={localProvider}
                price={price}
                tx={tx}
                writeContracts={writeContracts}
                readContracts={readContracts}
                blockExplorer={blockExplorer}
                nonce={nonce}
                signaturesRequired={signaturesRequired}
              />
            ) : (
              <div></div>
            )}
          </>
        </Col>
      </Row>
      <Row justify="space-around">
        <Col>
          <h2 style={{ marginTop: 16 }}>Executed Transactions: #{nonce ? nonce.toNumber() : "-"}</h2>
          <List
            pagination={{ pageSize: 5 }}
            bordered
            dataSource={executeTransactionEvents}
            renderItem={item => {
              return (
                <TransactionListItem
                  item={item}
                  mainnetProvider={mainnetProvider}
                  blockExplorer={blockExplorer}
                  price={price}
                  readContracts={readContracts}
                  contractName={contractName}
                />
              );
            }}
          />
        </Col>
      </Row>
    </div>
  );
}
