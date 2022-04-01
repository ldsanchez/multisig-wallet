import React, { useState, useEffect } from "react";
import { Button, Modal, InputNumber } from "antd";
import { PlusOutlined, DeleteOutlined } from "@ant-design/icons";
import { ethers } from "ethers";
import AddressInput from "./AddressInput";
import EtherInput from "./EtherInput";
import CreateMultisigWalletModalSentOverlay from "./CreateMultisigWalletModalSentOverlay";

export default function CreateMultisigWalletModal({
  price,
  selectedChainId,
  mainnetProvider,
  address,
  tx,
  writeContracts,
  contractName,
  isCreateModalVisible,
  setIsCreateModalVisible,
}) {

  // Transaction State
  const [txSent, setTxSent] = useState(false);
  const [txError, setTxError] = useState(false);
  const [txSuccess, setTxSuccess] = useState(false);

  const [amount, setAmount] = useState("0");
  const [owners, setOwners] = useState([""]);

  const [pendingCreate, setPendingCreate] = useState(false);
  const [signaturesRequired, setSignaturesRequired] = useState(false);

  useEffect(() => {
    if (address) {
      setOwners([address, ""]);
    }
  }, [address]);

  const showCreateModal = () => {
    setIsCreateModalVisible(true);
  };

  const addOwnerField = () => {
    const newOwners = [...owners, ''];
    setOwners(newOwners);
  };

  const updateOwner = (value, index) => {
    const newOwners = [...owners];
    newOwners[index] = value;
    setOwners(newOwners);
  };

  const removeOwnerField = index => {
    const newOwners = [...owners];
    newOwners.splice(index, 1);
    setOwners(newOwners);
  };

  const resetState = () => {
    setPendingCreate(false);
    setTxSent(false);
    setTxError(false);
    setTxSuccess(false);
    setOwners([""]);
    setAmount("0");
    setSignaturesRequired(false);
  };

  const validateFields = () => {
    let valid = true;

    if (signaturesRequired > owners.length) {
      console.log("Validation error: signaturesRequired is greather than number of owners.");
      valid = false;
    }

    owners.forEach((owner, index) => {
      let err;
      if (!owner) {
        err = "Required Input";
      } else if (owners.slice(0, index).some((o) => o === owner)) {
        err = "Duplicate Owner";
      } else if (!ethers.utils.isAddress(owner)) {
        err = "Bad format";
      }

      if (err) {
        console.log("Owners field error: ", err);
        valid = false;
      }
    });

    return valid;
  };

  const handleSubmit = () => {
    try {
      setPendingCreate(true);

      if (!validateFields()) {
        setPendingCreate(false);
        throw new Error("Field validation failed.");
      }

      tx(
        writeContracts[contractName].create(selectedChainId, owners, signaturesRequired, {
          value: ethers.utils.parseEther("" + parseFloat(amount).toFixed(12)),
        }),
        update => {
          if (update && (update.error || update.reason)) {
            console.log("tx update error!");
            setPendingCreate(false);
            setTxError(true);
          }

          if (update && update.code) {
            setPendingCreate(false);
            setTxSent(false);
          }

          if (update && (update.status === "confirmed" || update.status === 1)) {
            console.log("tx update confirmed!");
            setPendingCreate(false);
            setTxSuccess(true);
            setTimeout(() => {
              setIsCreateModalVisible(false);
              resetState();
            }, 2500);
          }
        },
      ).catch(err => {
        setPendingCreate(false);
        throw err;
      });

      setTxSent(true);
    } catch (e) {
      console.log("CREATE MUTLI-SIG SUBMIT FAILED: ", e);
    }
  };

  const handleCancel = () => {
    setIsCreateModalVisible(false);
  };

  return (
    <>
      <Button type="primary" style={{ marginRight: 10 }} onClick={showCreateModal}>
        Create
      </Button>
      <Modal
        title="Create Multisig Wallet"
        visible={isCreateModalVisible}
        onCancel={handleCancel}
        footer={[
          <Button key="back" onClick={handleCancel}>
            Cancel
          </Button>,
          <Button key="submit" type="primary" loading={pendingCreate} onClick={handleSubmit}>
            Create
          </Button>,
        ]}
      >
        {txSent && (
          <CreateMultisigWalletModalSentOverlay
            txError={txError}
            txSuccess={txSuccess}
            pendingText="Creating Multisig Wallet"
            successText="Multisig Wallet Created"
            errorText="Transaction Failed"
          />
        )}
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          {owners.map((owner, index) => (
            <div key={index} style={{ display: "flex", gap: "1rem" }}>
              <div style={{ width: "90%" }}>
                <AddressInput
                  autoFocus
                  ensProvider={mainnetProvider}
                  placeholder={"Owner address"}
                  value={owner}
                  onChange={val => updateOwner(val, index)}
                />
              </div>
              {index > 0 && (
                <Button style={{ padding: "0 0.5rem" }} danger onClick={() => removeOwnerField(index)}>
                  <DeleteOutlined />
                </Button>
              )}
            </div>
          ))}
          <div style={{ display: "flex", justifyContent: "flex-end", width: "90%" }}>
            <Button onClick={addOwnerField}>
              <PlusOutlined />
            </Button>
          </div>
          <div style={{ width: "90%" }}>
            <InputNumber
              style={{ width: "100%" }}
              placeholder="Number of signatures required"
              value={signaturesRequired}
              onChange={setSignaturesRequired}
            />
          </div>
          <div style={{ width: "90%" }}>
            <EtherInput
              placeholder="Fund your multi-sig (optional)"
              price={price}
              mode="USD"
              value={amount}
              onChange={setAmount}
            />
          </div>
        </div>
      </Modal>
    </>
  );
}
